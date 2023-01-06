# Zynq 下 PS 裸机支持 phy-ksz9031 

## 实现

zynq 的 `vivado v2018.3` 是不支持 `ksz9031`这款`phy`芯片的，所以需要我们手动添加获取`phy speed`的接口，

主要修改两个文件`xaxiemacif_physpeed.c` 和 `xemacpsif_physpeed.c`, 其路径在以下

`<Vivado安装路径>\Xilinx\SDK\2018.3\data\embeddedsw\ThirdParty\sw_services\lwip202_v1_2\src\contrib\ports\xilinx\netif`



打开两个文件，分别添加如下代码

```c
// xaxiemacif_physpeed.c 
// 添加 get_phy_speed_ksz9031，并且在 get_IEEE_phy_speed 调用该函数 get_phy_speed_ksz9031

#define MICREL_PHY_IDENTIFIER 			0x22
#define MICREL_PHY_KSZ9031_MODEL		0x220

unsigned int get_phy_speed_ksz9031(XAxiEthernet*xaxiemacp,u32phy_addr){
	u16 control;
	u16 status;
	u16 partner_capabilities;
	xil_printf("Start PHY auto negotiation\r\n");

	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,2);
	XAxiEthernet_PhyRead(xaxiemacp,phy_addr,IEEE_CONTROL_REG_MAC,&control);
	//control|=IEEE_RGMII_TXRX_CLOCK_DELAYED_MASK;	control&=~(0x10);
	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_CONTROL_REG_MAC,control);

	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,0);

	XAxiEthernet_PhyRead(xaxiemacp,phy_addr,IEEE_AUTONEGO_ADVERTISE_REG,&control);
	control |=IEEE_ASYMMETRIC_PAUSE_MASK;
	control |=IEEE_PAUSE_MASK;
	control |=ADVERTISE_100;
	control |=ADVERTISE_10;
	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_AUTONEGO_ADVERTISE_REG,control);

	XAxiEthernet_PhyRead(xaxiemacp,phy_addr,IEEE_1000_ADVERTISE_REG_OFFSET,
																	&control);
	control |=ADVERTISE_1000;
	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_1000_ADVERTISE_REG_OFFSET,
																	control);

	XAxiEthernet_PhyWrite(xaxiemacp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,0);
	XAxiEthernet_PhyRead(xaxiemacp,phy_addr,IEEE_COPPER_SPECIFIC_CONTROL_REG,
																&control);
	control |=(7<<12);	/* max number of gigabit attempts */
	control |=(1<<11);	/* enable downshift */
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_COPPER_SPECIFIC_CONTROL_REG,
																control);
	XAxiEthernet_PhyRead(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
	control |= IEEE_CTRL_AUTONEGOTIATE_ENABLE;
	control |= IEEE_STAT_AUTONEGOTIATE_RESTART;

	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);

	XAxiEthernet_PhyRead(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
	control |= IEEE_CTRL_RESET_MASK;
	XAxiEthernet_PhyWrite(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);

	while(1){
		XAxiEthernet_PhyRead(xaxiemacp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
		if(control & IEEE_CTRL_RESET_MASK)
			continue;
		else
			break;
	}
	xil_printf("Waiting for PHY to complete autonegotiation.\r\n");

	XAxiEthernet_PhyRead(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET,&status);
	while(!(status & IEEE_STAT_AUTONEGOTIATE_COMPLETE)){
		sleep(1);
		XAxiEthernet_PhyRead(xaxiemacp, phy_addr, IEEE_STATUS_REG_OFFSET, &status);
	}

	xil_printf("autonegotiation complete \r\n");

	XAxiEthernet_PhyRead(xaxiemacp, phy_addr,0x1f,&partner_capabilities);

	if((partner_capabilities &0x40)==0x40)/* 1000Mbps */
		return 1000;
	else if((partner_capabilities &0x20)==0x20)/* 100Mbps */
		return 100;
	else if((partner_capabilities &0x10)==0x10)/* 10Mbps */
		return 10;
	else
		return 0;
}

unsigned get_IEEE_phy_speed(XAxiEthernet *xaxiemacp)
{
	u16 phy_identifier;
	u16 phy_model;
	u8 phytype;

#ifdef XPAR_AXIETHERNET_0_BASEADDR
	u32 phy_addr = detect_phy(xaxiemacp);

	/* Get the PHY Identifier and Model number */
	XAxiEthernet_PhyRead(xaxiemacp, phy_addr, PHY_IDENTIFIER_1_REG, &phy_identifier);
	XAxiEthernet_PhyRead(xaxiemacp, phy_addr, PHY_IDENTIFIER_2_REG, &phy_model);

/* Depending upon what manufacturer PHY is connected, a different mask is
 * needed to determine the specific model number of the PHY. */
	if (phy_identifier == MARVEL_PHY_IDENTIFIER) {
		phy_model = phy_model & MARVEL_PHY_MODEL_NUM_MASK;

		if (phy_model == MARVEL_PHY_88E1116R_MODEL) {
			return get_phy_speed_88E1116R(xaxiemacp, phy_addr);
		} else if (phy_model == MARVEL_PHY_88E1111_MODEL) {
			return get_phy_speed_88E1111(xaxiemacp, phy_addr);
		}
	} else if (phy_identifier == TI_PHY_IDENTIFIER) {
		phy_model = phy_model & TI_PHY_DP83867_MODEL;
		phytype = XAxiEthernet_GetPhysicalInterface(xaxiemacp);

		if (phy_model == TI_PHY_DP83867_MODEL && phytype == XAE_PHY_TYPE_SGMII) {
			return get_phy_speed_TI_DP83867_SGMII(xaxiemacp, phy_addr);
		}

		if (phy_model == TI_PHY_DP83867_MODEL) {
			return get_phy_speed_TI_DP83867(xaxiemacp, phy_addr);
		}
	}	
+	else if(phy_identifier==MICREL_PHY_IDENTIFIER)
+	{
+		xil_printf("Phy%disKSZ9031\n\r",phy_addr);
+		get_phy_speed_ksz9031(xaxiemacp,phy_addr);
+	}
	else {
	    LWIP_DEBUGF(NETIF_DEBUG, ("XAxiEthernet get_IEEE_phy_speed: Detected PHY with unknown identifier/model.\r\n"));
	}
#endif
#ifdef PCM_PMA_CORE_PRESENT
	return get_phy_negotiated_speed(xaxiemacp, phy_addr);
#endif
}
```



```c
// xemacpsif_physpeed.c
// 添加 get_phy_speed_ksz9031 函数，并且在 get_IEEE_phy_speed 中添加 get_phy_speed_ksz9031

#define MICREL_PHY_IDENTIFIER 		0x22
#define MICREL_PHY_KSZ9031_MODEL 	0x220

static u32_t get_phy_speed_ksz9031(XEmacPs *xemacpsp, u32_t phy_addr){
	u16_t temp;
	u16_t control;
	u16_t status;
	u16_t status_speed;
	u32_t timeout_counter=0;
	u32_t temp_speed;
	u32_t phyregtemp;

	xil_printf("Start PHY auto negotiation\r\n");

	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,2);
	XEmacPs_PhyRead(xemacpsp,phy_addr,IEEE_CONTROL_REG_MAC,&control);
	control|=IEEE_RGMII_TXRX_CLOCK_DELAYED_MASK;
	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_CONTROL_REG_MAC,control);

	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,0);

	XEmacPs_PhyRead(xemacpsp,phy_addr,IEEE_AUTONEGO_ADVERTISE_REG,&control);
	control|=IEEE_ASYMMETRIC_PAUSE_MASK;
	control|=IEEE_PAUSE_MASK;
	control|=ADVERTISE_100;
	control|=ADVERTISE_10;
	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_AUTONEGO_ADVERTISE_REG,control);

	XEmacPs_PhyRead(xemacpsp,phy_addr,IEEE_1000_ADVERTISE_REG_OFFSET,
					&control);
	control|=ADVERTISE_1000;
	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_1000_ADVERTISE_REG_OFFSET,
					control);

	XEmacPs_PhyWrite(xemacpsp,phy_addr,IEEE_PAGE_ADDRESS_REGISTER,0);
	XEmacPs_PhyRead(xemacpsp,phy_addr,IEEE_COPPER_SPECIFIC_CONTROL_REG,
																&control);
	control|=(7<<12);	/* max number of gigabit attempts */
	control |=(1<<11);	/* enable downshift */
	XEmacPs_PhyWrite(xemacpsp, phy_addr, IEEE_COPPER_SPECIFIC_CONTROL_REG,
																control);
	XEmacPs_PhyRead(xemacpsp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
	control |= IEEE_CTRL_AUTONEGOTIATE_ENABLE;
	control |= IEEE_STAT_AUTONEGOTIATE_RESTART;
	XEmacPs_PhyWrite(xemacpsp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);

	XEmacPs_PhyRead(xemacpsp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
	control |= IEEE_CTRL_RESET_MASK;
	XEmacPs_PhyWrite(xemacpsp, phy_addr, IEEE_CONTROL_REG_OFFSET, control);

	while(1){
		XEmacPs_PhyRead(xemacpsp, phy_addr, IEEE_CONTROL_REG_OFFSET,&control);
		if(control & IEEE_CTRL_RESET_MASK)
			continue;
		else
			break;
	}

	XEmacPs_PhyRead(xemacpsp, phy_addr, IEEE_STATUS_REG_OFFSET,&status);

	xil_printf("Waiting for PHY to complete autonegotiation.\r\n");

	while(!(status & IEEE_STAT_AUTONEGOTIATE_COMPLETE)){
		sleep(1);
		XEmacPs_PhyRead(xemacpsp, phy_addr,
						IEEE_COPPER_SPECIFIC_STATUS_REG_2,&temp);
		timeout_counter++;

		if(timeout_counter ==30){
			xil_printf("Auto negotiation error \r\n");
			return;
		}
		XEmacPs_PhyRead(xemacpsp, phy_addr, IEEE_STATUS_REG_OFFSET,&status);
	}
	xil_printf("auto negotiation complete \r\n");

	XEmacPs_PhyRead(xemacpsp, phy_addr,0x1f,
					&status_speed);

	if((status_speed & 0x40)==0x40)/* 1000Mbps */
		return 1000;
	else if((status_speed & 0x20)==0x20)/* 100Mbps */
		return 100;
	else if((status_speed & 0x10)==0x10)/* 10Mbps */
		return 10;
	else
		return 0;
	return XST_SUCCESS;
}
static u32_t get_IEEE_phy_speed(XEmacPs *xemacpsp, u32_t phy_addr)
{
	u16_t phy_identity;
	u32_t RetStatus;

	XEmacPs_PhyRead(xemacpsp, phy_addr, PHY_IDENTIFIER_1_REG,
					&phy_identity);
+	if(phy_identity==MICREL_PHY_IDENTIFIER){
+		RetStatus = get_phy_speed_ksz9031(xemacpsp,phy_addr);
+	} else 
        if (phy_identity == PHY_TI_IDENTIFIER) {
		RetStatus = get_TI_phy_speed(xemacpsp, phy_addr);
	} else if (phy_identity == PHY_REALTEK_IDENTIFIER) {
		RetStatus = get_Realtek_phy_speed(xemacpsp, phy_addr);
	} else {
		RetStatus = get_Marvell_phy_speed(xemacpsp, phy_addr);
	}

	return RetStatus;
}
```



之后正常通过SDK生成 `lwip_echo` 工程, 编译后就可以了。

## 参考

1. [ZYNQ. LwIP.PHY.KSZ9031RNX](https://www.cnblogs.com/protogenoi/p/9779405.html)
2. https://blog.csdn.net/weixin_42066185/article/details/104495586
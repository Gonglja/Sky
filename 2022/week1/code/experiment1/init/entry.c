/*
 * @Author: Gonglja
 * @Date: 2022-03-15 09:56:12
 * @LastEditTime: 2022-03-15 11:16:08
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: /os/init/entry.c
 */
#include "types.h"

int kern_entry(){

    int8_t hello[] = "hello,world!!!\n";
    int8_t *c;
    uint16_t *input = (uint16_t *)0xB8000;
    c = (int8_t *)&hello;
    while (*c) {
        *input++ = *c++ | (15 & 0xf) << 8;
    }
    
    return 0;
}
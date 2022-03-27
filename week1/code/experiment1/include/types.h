/*
 * @Author: Gonglja
 * @Date: 2022-03-15 09:46:50
 * @LastEditTime: 2022-03-15 09:55:01
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: /os/include/types.h
 */


#ifndef INCLUDE_TYPES_H_ 
#define INCLUDE_TYPES_H_

#ifndef NULL
    #define NULL 0
#endif

#ifndef TRUE
    #define TRUE  1
    #define FALSE 0
#endif

typedef char            int8_t;
typedef unsigned char   uint8_t; 
typedef short           int16_t;
typedef unsigned short  uint16_t; 
typedef int             int32_t; 
typedef unsigned int    uint32_t;

#endif


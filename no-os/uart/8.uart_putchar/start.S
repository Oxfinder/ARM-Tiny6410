/****************************************************************
    Copyright (C) 2015 Sean Guo. All rights reserved.
					      									  
    > File Name:         < start.S >
    > Author:            < Sean Guo >
    > Mail:              < iseanxp+code@gmail.com >
    > Created Time:      < 2015/07/31 >
    > Last Changed: 
    > Description:		FriendlyARM - Tiny6410 裸机程序 - 汇编启动程序

	ARM上电后，先执行start.S, 配置好相应的寄存器后，调用c语言的main函数;
	配置寄存器，开启icache;
	调用clock_init()时钟配置函数;
	调用C语言main()函数;
****************************************************************/
.global _start							
	
_start:
	// ----1. 配置ARM CPU寄存器的外设地址----
	// 把外设的基地址告诉CPU
    ldr r0, =0x70000000 					//对于6410来说,内存(0x00000000～0x60000000),外设(0x70000000-0x7fffffff)
    orr r0, r0, #0x13						//外设大小:256M
	// 在基于ARM的嵌入式应用系统中，存储系统通常是通过系统控制协处理器CP15完成的。
	// CP15包含16个32位的寄存器，其编号为0~15。
	// MCR : ARM寄存器到协处理器寄存器的数据传送
    mcr p15,0,r0,c15,c2,4       			//把r0的值(包括了外设基地址+外设大小)告诉cpu
    
	// ----2. 关看门狗----
	//	Watch Dog - WDCON寄存器 - 0x7E004000 , Watchdog timer control register
	ldr r0, =0x7E004000
	mov r1, #0
	str r1, [r0] 							// 将r0寄存器的值写入地址值为r1的（存储器）内存中

	// ----3. 设置栈 ----
	// C语言需要栈;
	// 栈有三个作用，包括：
	//		1. 保存现场；
	//		2. 传递参数: 汇编代码调用C函数时，需传递参数；
	//		3. 保存临时变量:包括函数的非静态局部变量以及编译器自动生成的其他临时变量；
	// 设置栈，其实就是设置SP寄存器，让其指向一块可用的内存。
	// SD 启动时，S3C6410的内部8K的SRAM被映射到0X0C000000，而ARM 默认的栈是递减的，所以可以让SP 指向0X0C002000；
	ldr sp, =0x0c002000	//栈可用空间: 0x0c002000 ~ 0x0c000000;
	
	// ----4. 开启icache ----
	// icache - instruction cache 指令高速缓冲存储器; 启动后提高CPU取指效率;
	// dcache - data cache, 数据高速缓冲存储器;
	// 		dcache是需要和页表搭配的（MMU），页表中要设置每个section/page是否cache和buffer
	// 		icache则是不依赖页表的
#ifdef  CONFIG_SYS_ICACHE_OFF
	// CP15 协处理器中的寄存器1 的bit[12]写1 可以启动icache，写0 可以停止icache。
	bic	r0, r0, #0x00001000					@ clear bit 12 (I) I-cache
#else
	// 没有定义宏命令CONFIG_SYS_ICACHE_OFF的情况下, 执行else分支;
	orr	r0, r0, #0x00001000					@ set bit 12 (I) I-cache
	// 0001 0000 0000 0000 b; bit12 = 1, set I-cache;
#endif
	mcr	p15, 0, r0, c1, c0, 0

	// ---- 5. 设置时钟 ----
	bl clock_init

	// ---- 6. 调用C函数main() ----
	bl main

halt:
	b halt	

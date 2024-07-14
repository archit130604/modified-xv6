
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a8010113          	addi	sp,sp,-1408 # 80008a80 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8ee70713          	addi	a4,a4,-1810 # 80008940 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	40c78793          	addi	a5,a5,1036 # 80006470 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc037>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	efa78793          	addi	a5,a5,-262 # 80000fa8 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7fc080e7          	jalr	2044(ra) # 80002928 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80010a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	b74080e7          	jalr	-1164(ra) # 80000d06 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80010a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	97690913          	addi	s2,s2,-1674 # 80010b18 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	9e4080e7          	jalr	-1564(ra) # 80001ba4 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	5aa080e7          	jalr	1450(ra) # 80002772 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	2e8080e7          	jalr	744(ra) # 800024be <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	6c0080e7          	jalr	1728(ra) # 800028d2 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80010a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	b8c080e7          	jalr	-1140(ra) # 80000dba <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	84450513          	addi	a0,a0,-1980 # 80010a80 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	b76080e7          	jalr	-1162(ra) # 80000dba <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72323          	sw	a5,-1882(a4) # 80010b18 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7b450513          	addi	a0,a0,1972 # 80010a80 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	a32080e7          	jalr	-1486(ra) # 80000d06 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	68c080e7          	jalr	1676(ra) # 8000297e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	78650513          	addi	a0,a0,1926 # 80010a80 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	ab8080e7          	jalr	-1352(ra) # 80000dba <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	76270713          	addi	a4,a4,1890 # 80010a80 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	73878793          	addi	a5,a5,1848 # 80010a80 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80010b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6f670713          	addi	a4,a4,1782 # 80010a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6e648493          	addi	s1,s1,1766 # 80010a80 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6aa70713          	addi	a4,a4,1706 # 80010a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80010b20 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	66e78793          	addi	a5,a5,1646 # 80010a80 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80010b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6da50513          	addi	a0,a0,1754 # 80010b18 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	0dc080e7          	jalr	220(ra) # 80002522 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	62050513          	addi	a0,a0,1568 # 80010a80 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	80e080e7          	jalr	-2034(ra) # 80000c76 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00241797          	auipc	a5,0x241
    8000047c:	1b878793          	addi	a5,a5,440 # 80241630 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5e07ab23          	sw	zero,1526(a5) # 80010b40 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	d5c50513          	addi	a0,a0,-676 # 800082c8 <digits+0x288>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	38f72123          	sw	a5,898(a4) # 80008900 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	586dad83          	lw	s11,1414(s11) # 80010b40 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	53050513          	addi	a0,a0,1328 # 80010b28 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	706080e7          	jalr	1798(ra) # 80000d06 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3d250513          	addi	a0,a0,978 # 80010b28 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	65c080e7          	jalr	1628(ra) # 80000dba <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3b648493          	addi	s1,s1,950 # 80010b28 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	4f2080e7          	jalr	1266(ra) # 80000c76 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	37650513          	addi	a0,a0,886 # 80010b48 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	49c080e7          	jalr	1180(ra) # 80000c76 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	4c4080e7          	jalr	1220(ra) # 80000cba <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1027a783          	lw	a5,258(a5) # 80008900 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	536080e7          	jalr	1334(ra) # 80000d5a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0d27b783          	ld	a5,210(a5) # 80008908 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0d273703          	ld	a4,210(a4) # 80008910 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2e8a0a13          	addi	s4,s4,744 # 80010b48 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0a048493          	addi	s1,s1,160 # 80008908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0a098993          	addi	s3,s3,160 # 80008910 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	c90080e7          	jalr	-880(ra) # 80002522 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	27a50513          	addi	a0,a0,634 # 80010b48 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	430080e7          	jalr	1072(ra) # 80000d06 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0227a783          	lw	a5,34(a5) # 80008900 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	02873703          	ld	a4,40(a4) # 80008910 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0187b783          	ld	a5,24(a5) # 80008908 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	24c98993          	addi	s3,s3,588 # 80010b48 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	00448493          	addi	s1,s1,4 # 80008908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	00490913          	addi	s2,s2,4 # 80008910 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	ba2080e7          	jalr	-1118(ra) # 800024be <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	21648493          	addi	s1,s1,534 # 80010b48 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fce7b523          	sd	a4,-54(a5) # 80008910 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	462080e7          	jalr	1122(ra) # 80000dba <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	18c48493          	addi	s1,s1,396 # 80010b48 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	340080e7          	jalr	832(ra) # 80000d06 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	3e2080e7          	jalr	994(ra) # 80000dba <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    800009ea:	7179                	addi	sp,sp,-48
    800009ec:	f406                	sd	ra,40(sp)
    800009ee:	f022                	sd	s0,32(sp)
    800009f0:	ec26                	sd	s1,24(sp)
    800009f2:	e84a                	sd	s2,16(sp)
    800009f4:	e44e                	sd	s3,8(sp)
    800009f6:	1800                	addi	s0,sp,48
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    800009f8:	03451793          	slli	a5,a0,0x34
    800009fc:	e7ad                	bnez	a5,80000a66 <kfree+0x7c>
    800009fe:	84aa                	mv	s1,a0
    80000a00:	00242797          	auipc	a5,0x242
    80000a04:	dc878793          	addi	a5,a5,-568 # 802427c8 <end>
    80000a08:	04f56f63          	bltu	a0,a5,80000a66 <kfree+0x7c>
    80000a0c:	47c5                	li	a5,17
    80000a0e:	07ee                	slli	a5,a5,0x1b
    80000a10:	04f57b63          	bgeu	a0,a5,80000a66 <kfree+0x7c>
        panic("kfree");
    int flag1=0;
    acquire(&lock_for_the_arr_of_ref);
    80000a14:	00010517          	auipc	a0,0x10
    80000a18:	16c50513          	addi	a0,a0,364 # 80010b80 <lock_for_the_arr_of_ref>
    80000a1c:	00000097          	auipc	ra,0x0
    80000a20:	2ea080e7          	jalr	746(ra) # 80000d06 <acquire>
    arr_of_ref[(uint64)pa >> PGSHIFT]--;
    80000a24:	00c4d793          	srli	a5,s1,0xc
    80000a28:	00279713          	slli	a4,a5,0x2
    80000a2c:	00010797          	auipc	a5,0x10
    80000a30:	18c78793          	addi	a5,a5,396 # 80010bb8 <arr_of_ref>
    80000a34:	97ba                	add	a5,a5,a4
    80000a36:	4398                	lw	a4,0(a5)
    80000a38:	377d                	addiw	a4,a4,-1
    80000a3a:	0007091b          	sext.w	s2,a4
    80000a3e:	c398                	sw	a4,0(a5)
    if (arr_of_ref[(uint64)pa >> PGSHIFT] < 0)
    80000a40:	02094b63          	bltz	s2,80000a76 <kfree+0x8c>
    {
        panic("kfree in ref_cont");
    }
    flag1=arr_of_ref[(uint64)pa >> PGSHIFT];
    release(&lock_for_the_arr_of_ref);
    80000a44:	00010517          	auipc	a0,0x10
    80000a48:	13c50513          	addi	a0,a0,316 # 80010b80 <lock_for_the_arr_of_ref>
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	36e080e7          	jalr	878(ra) # 80000dba <release>
    // Fill with junk to catch dangling refs.
    if (flag1)
    80000a54:	02090963          	beqz	s2,80000a86 <kfree+0x9c>

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
}
    80000a58:	70a2                	ld	ra,40(sp)
    80000a5a:	7402                	ld	s0,32(sp)
    80000a5c:	64e2                	ld	s1,24(sp)
    80000a5e:	6942                	ld	s2,16(sp)
    80000a60:	69a2                	ld	s3,8(sp)
    80000a62:	6145                	addi	sp,sp,48
    80000a64:	8082                	ret
        panic("kfree");
    80000a66:	00007517          	auipc	a0,0x7
    80000a6a:	5fa50513          	addi	a0,a0,1530 # 80008060 <digits+0x20>
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	ad0080e7          	jalr	-1328(ra) # 8000053e <panic>
        panic("kfree in ref_cont");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5f250513          	addi	a0,a0,1522 # 80008068 <digits+0x28>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	ac0080e7          	jalr	-1344(ra) # 8000053e <panic>
    memset(pa, 1, PGSIZE);
    80000a86:	6605                	lui	a2,0x1
    80000a88:	4585                	li	a1,1
    80000a8a:	8526                	mv	a0,s1
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	376080e7          	jalr	886(ra) # 80000e02 <memset>
    acquire(&kmem.lock);
    80000a94:	00010997          	auipc	s3,0x10
    80000a98:	0ec98993          	addi	s3,s3,236 # 80010b80 <lock_for_the_arr_of_ref>
    80000a9c:	00010917          	auipc	s2,0x10
    80000aa0:	0fc90913          	addi	s2,s2,252 # 80010b98 <kmem>
    80000aa4:	854a                	mv	a0,s2
    80000aa6:	00000097          	auipc	ra,0x0
    80000aaa:	260080e7          	jalr	608(ra) # 80000d06 <acquire>
    r->next = kmem.freelist;
    80000aae:	0309b783          	ld	a5,48(s3)
    80000ab2:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000ab4:	0299b823          	sd	s1,48(s3)
    release(&kmem.lock);
    80000ab8:	854a                	mv	a0,s2
    80000aba:	00000097          	auipc	ra,0x0
    80000abe:	300080e7          	jalr	768(ra) # 80000dba <release>
    80000ac2:	bf59                	j	80000a58 <kfree+0x6e>

0000000080000ac4 <freerange>:
{
    80000ac4:	7139                	addi	sp,sp,-64
    80000ac6:	fc06                	sd	ra,56(sp)
    80000ac8:	f822                	sd	s0,48(sp)
    80000aca:	f426                	sd	s1,40(sp)
    80000acc:	f04a                	sd	s2,32(sp)
    80000ace:	ec4e                	sd	s3,24(sp)
    80000ad0:	e852                	sd	s4,16(sp)
    80000ad2:	e456                	sd	s5,8(sp)
    80000ad4:	e05a                	sd	s6,0(sp)
    80000ad6:	0080                	addi	s0,sp,64
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000ad8:	6785                	lui	a5,0x1
    80000ada:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ade:	9526                	add	a0,a0,s1
    80000ae0:	74fd                	lui	s1,0xfffff
    80000ae2:	8ce9                	and	s1,s1,a0
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ae4:	97a6                	add	a5,a5,s1
    80000ae6:	04f5e863          	bltu	a1,a5,80000b36 <freerange+0x72>
    80000aea:	89ae                	mv	s3,a1
        acquire(&lock_for_the_arr_of_ref);
    80000aec:	00010917          	auipc	s2,0x10
    80000af0:	09490913          	addi	s2,s2,148 # 80010b80 <lock_for_the_arr_of_ref>
        arr_of_ref[(uint64)p >> PGSHIFT]++;
    80000af4:	00010b17          	auipc	s6,0x10
    80000af8:	0c4b0b13          	addi	s6,s6,196 # 80010bb8 <arr_of_ref>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000afc:	6a85                	lui	s5,0x1
    80000afe:	6a09                	lui	s4,0x2
        acquire(&lock_for_the_arr_of_ref);
    80000b00:	854a                	mv	a0,s2
    80000b02:	00000097          	auipc	ra,0x0
    80000b06:	204080e7          	jalr	516(ra) # 80000d06 <acquire>
        arr_of_ref[(uint64)p >> PGSHIFT]++;
    80000b0a:	00c4d793          	srli	a5,s1,0xc
    80000b0e:	078a                	slli	a5,a5,0x2
    80000b10:	97da                	add	a5,a5,s6
    80000b12:	4398                	lw	a4,0(a5)
    80000b14:	2705                	addiw	a4,a4,1
    80000b16:	c398                	sw	a4,0(a5)
        release(&lock_for_the_arr_of_ref);
    80000b18:	854a                	mv	a0,s2
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	2a0080e7          	jalr	672(ra) # 80000dba <release>
        kfree(p);
    80000b22:	8526                	mv	a0,s1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	ec6080e7          	jalr	-314(ra) # 800009ea <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b2c:	87a6                	mv	a5,s1
    80000b2e:	94d6                	add	s1,s1,s5
    80000b30:	97d2                	add	a5,a5,s4
    80000b32:	fcf9f7e3          	bgeu	s3,a5,80000b00 <freerange+0x3c>
}
    80000b36:	70e2                	ld	ra,56(sp)
    80000b38:	7442                	ld	s0,48(sp)
    80000b3a:	74a2                	ld	s1,40(sp)
    80000b3c:	7902                	ld	s2,32(sp)
    80000b3e:	69e2                	ld	s3,24(sp)
    80000b40:	6a42                	ld	s4,16(sp)
    80000b42:	6aa2                	ld	s5,8(sp)
    80000b44:	6b02                	ld	s6,0(sp)
    80000b46:	6121                	addi	sp,sp,64
    80000b48:	8082                	ret

0000000080000b4a <kinit>:
{
    80000b4a:	1101                	addi	sp,sp,-32
    80000b4c:	ec06                	sd	ra,24(sp)
    80000b4e:	e822                	sd	s0,16(sp)
    80000b50:	e426                	sd	s1,8(sp)
    80000b52:	1000                	addi	s0,sp,32
    initlock(&kmem.lock, "kmem");
    80000b54:	00010497          	auipc	s1,0x10
    80000b58:	02c48493          	addi	s1,s1,44 # 80010b80 <lock_for_the_arr_of_ref>
    80000b5c:	00007597          	auipc	a1,0x7
    80000b60:	52458593          	addi	a1,a1,1316 # 80008080 <digits+0x40>
    80000b64:	00010517          	auipc	a0,0x10
    80000b68:	03450513          	addi	a0,a0,52 # 80010b98 <kmem>
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	10a080e7          	jalr	266(ra) # 80000c76 <initlock>
    initlock(&lock_for_the_arr_of_ref, "arr_of_ref");
    80000b74:	00007597          	auipc	a1,0x7
    80000b78:	51458593          	addi	a1,a1,1300 # 80008088 <digits+0x48>
    80000b7c:	8526                	mv	a0,s1
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	0f8080e7          	jalr	248(ra) # 80000c76 <initlock>
    acquire(&lock_for_the_arr_of_ref);
    80000b86:	8526                	mv	a0,s1
    80000b88:	00000097          	auipc	ra,0x0
    80000b8c:	17e080e7          	jalr	382(ra) # 80000d06 <acquire>
    for (int i = 0; i < (PGROUNDUP(PHYSTOP) >> PGSHIFT); i++)
    80000b90:	00010797          	auipc	a5,0x10
    80000b94:	02878793          	addi	a5,a5,40 # 80010bb8 <arr_of_ref>
    80000b98:	00230717          	auipc	a4,0x230
    80000b9c:	02070713          	addi	a4,a4,32 # 80230bb8 <pid_lock>
        arr_of_ref[i] = 0;
    80000ba0:	0007a023          	sw	zero,0(a5)
    for (int i = 0; i < (PGROUNDUP(PHYSTOP) >> PGSHIFT); i++)
    80000ba4:	0791                	addi	a5,a5,4
    80000ba6:	fee79de3          	bne	a5,a4,80000ba0 <kinit+0x56>
    release(&lock_for_the_arr_of_ref);
    80000baa:	00010517          	auipc	a0,0x10
    80000bae:	fd650513          	addi	a0,a0,-42 # 80010b80 <lock_for_the_arr_of_ref>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	208080e7          	jalr	520(ra) # 80000dba <release>
    freerange(end, (void *)PHYSTOP);
    80000bba:	45c5                	li	a1,17
    80000bbc:	05ee                	slli	a1,a1,0x1b
    80000bbe:	00242517          	auipc	a0,0x242
    80000bc2:	c0a50513          	addi	a0,a0,-1014 # 802427c8 <end>
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	efe080e7          	jalr	-258(ra) # 80000ac4 <freerange>
}
    80000bce:	60e2                	ld	ra,24(sp)
    80000bd0:	6442                	ld	s0,16(sp)
    80000bd2:	64a2                	ld	s1,8(sp)
    80000bd4:	6105                	addi	sp,sp,32
    80000bd6:	8082                	ret

0000000080000bd8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bd8:	1101                	addi	sp,sp,-32
    80000bda:	ec06                	sd	ra,24(sp)
    80000bdc:	e822                	sd	s0,16(sp)
    80000bde:	e426                	sd	s1,8(sp)
    80000be0:	e04a                	sd	s2,0(sp)
    80000be2:	1000                	addi	s0,sp,32
    struct run *r;

    acquire(&kmem.lock);
    80000be4:	00010517          	auipc	a0,0x10
    80000be8:	fb450513          	addi	a0,a0,-76 # 80010b98 <kmem>
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	11a080e7          	jalr	282(ra) # 80000d06 <acquire>
    r = kmem.freelist;
    80000bf4:	00010497          	auipc	s1,0x10
    80000bf8:	fbc4b483          	ld	s1,-68(s1) # 80010bb0 <kmem+0x18>
    if (r)
    80000bfc:	c4a5                	beqz	s1,80000c64 <kalloc+0x8c>
        kmem.freelist = r->next;
    80000bfe:	609c                	ld	a5,0(s1)
    80000c00:	00010917          	auipc	s2,0x10
    80000c04:	f8090913          	addi	s2,s2,-128 # 80010b80 <lock_for_the_arr_of_ref>
    80000c08:	02f93823          	sd	a5,48(s2)
    release(&kmem.lock);
    80000c0c:	00010517          	auipc	a0,0x10
    80000c10:	f8c50513          	addi	a0,a0,-116 # 80010b98 <kmem>
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	1a6080e7          	jalr	422(ra) # 80000dba <release>

    if (r)
    {
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000c1c:	6605                	lui	a2,0x1
    80000c1e:	4595                	li	a1,5
    80000c20:	8526                	mv	a0,s1
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	1e0080e7          	jalr	480(ra) # 80000e02 <memset>
        acquire(&lock_for_the_arr_of_ref);
    80000c2a:	854a                	mv	a0,s2
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	0da080e7          	jalr	218(ra) # 80000d06 <acquire>
        arr_of_ref[(uint64)r >> PGSHIFT]++;
    80000c34:	00c4d793          	srli	a5,s1,0xc
    80000c38:	00279713          	slli	a4,a5,0x2
    80000c3c:	00010797          	auipc	a5,0x10
    80000c40:	f7c78793          	addi	a5,a5,-132 # 80010bb8 <arr_of_ref>
    80000c44:	97ba                	add	a5,a5,a4
    80000c46:	4398                	lw	a4,0(a5)
    80000c48:	2705                	addiw	a4,a4,1
    80000c4a:	c398                	sw	a4,0(a5)
        release(&lock_for_the_arr_of_ref);
    80000c4c:	854a                	mv	a0,s2
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	16c080e7          	jalr	364(ra) # 80000dba <release>
    }
    return (void *)r;
}
    80000c56:	8526                	mv	a0,s1
    80000c58:	60e2                	ld	ra,24(sp)
    80000c5a:	6442                	ld	s0,16(sp)
    80000c5c:	64a2                	ld	s1,8(sp)
    80000c5e:	6902                	ld	s2,0(sp)
    80000c60:	6105                	addi	sp,sp,32
    80000c62:	8082                	ret
    release(&kmem.lock);
    80000c64:	00010517          	auipc	a0,0x10
    80000c68:	f3450513          	addi	a0,a0,-204 # 80010b98 <kmem>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	14e080e7          	jalr	334(ra) # 80000dba <release>
    if (r)
    80000c74:	b7cd                	j	80000c56 <kalloc+0x7e>

0000000080000c76 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c76:	1141                	addi	sp,sp,-16
    80000c78:	e422                	sd	s0,8(sp)
    80000c7a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c7c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c7e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c82:	00053823          	sd	zero,16(a0)
}
    80000c86:	6422                	ld	s0,8(sp)
    80000c88:	0141                	addi	sp,sp,16
    80000c8a:	8082                	ret

0000000080000c8c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c8c:	411c                	lw	a5,0(a0)
    80000c8e:	e399                	bnez	a5,80000c94 <holding+0x8>
    80000c90:	4501                	li	a0,0
  return r;
}
    80000c92:	8082                	ret
{
    80000c94:	1101                	addi	sp,sp,-32
    80000c96:	ec06                	sd	ra,24(sp)
    80000c98:	e822                	sd	s0,16(sp)
    80000c9a:	e426                	sd	s1,8(sp)
    80000c9c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c9e:	6904                	ld	s1,16(a0)
    80000ca0:	00001097          	auipc	ra,0x1
    80000ca4:	ee8080e7          	jalr	-280(ra) # 80001b88 <mycpu>
    80000ca8:	40a48533          	sub	a0,s1,a0
    80000cac:	00153513          	seqz	a0,a0
}
    80000cb0:	60e2                	ld	ra,24(sp)
    80000cb2:	6442                	ld	s0,16(sp)
    80000cb4:	64a2                	ld	s1,8(sp)
    80000cb6:	6105                	addi	sp,sp,32
    80000cb8:	8082                	ret

0000000080000cba <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cba:	1101                	addi	sp,sp,-32
    80000cbc:	ec06                	sd	ra,24(sp)
    80000cbe:	e822                	sd	s0,16(sp)
    80000cc0:	e426                	sd	s1,8(sp)
    80000cc2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc4:	100024f3          	csrr	s1,sstatus
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ccc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cce:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cd2:	00001097          	auipc	ra,0x1
    80000cd6:	eb6080e7          	jalr	-330(ra) # 80001b88 <mycpu>
    80000cda:	5d3c                	lw	a5,120(a0)
    80000cdc:	cf89                	beqz	a5,80000cf6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cde:	00001097          	auipc	ra,0x1
    80000ce2:	eaa080e7          	jalr	-342(ra) # 80001b88 <mycpu>
    80000ce6:	5d3c                	lw	a5,120(a0)
    80000ce8:	2785                	addiw	a5,a5,1
    80000cea:	dd3c                	sw	a5,120(a0)
}
    80000cec:	60e2                	ld	ra,24(sp)
    80000cee:	6442                	ld	s0,16(sp)
    80000cf0:	64a2                	ld	s1,8(sp)
    80000cf2:	6105                	addi	sp,sp,32
    80000cf4:	8082                	ret
    mycpu()->intena = old;
    80000cf6:	00001097          	auipc	ra,0x1
    80000cfa:	e92080e7          	jalr	-366(ra) # 80001b88 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cfe:	8085                	srli	s1,s1,0x1
    80000d00:	8885                	andi	s1,s1,1
    80000d02:	dd64                	sw	s1,124(a0)
    80000d04:	bfe9                	j	80000cde <push_off+0x24>

0000000080000d06 <acquire>:
{
    80000d06:	1101                	addi	sp,sp,-32
    80000d08:	ec06                	sd	ra,24(sp)
    80000d0a:	e822                	sd	s0,16(sp)
    80000d0c:	e426                	sd	s1,8(sp)
    80000d0e:	1000                	addi	s0,sp,32
    80000d10:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	fa8080e7          	jalr	-88(ra) # 80000cba <push_off>
  if(holding(lk))
    80000d1a:	8526                	mv	a0,s1
    80000d1c:	00000097          	auipc	ra,0x0
    80000d20:	f70080e7          	jalr	-144(ra) # 80000c8c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d24:	4705                	li	a4,1
  if(holding(lk))
    80000d26:	e115                	bnez	a0,80000d4a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d28:	87ba                	mv	a5,a4
    80000d2a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d2e:	2781                	sext.w	a5,a5
    80000d30:	ffe5                	bnez	a5,80000d28 <acquire+0x22>
  __sync_synchronize();
    80000d32:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d36:	00001097          	auipc	ra,0x1
    80000d3a:	e52080e7          	jalr	-430(ra) # 80001b88 <mycpu>
    80000d3e:	e888                	sd	a0,16(s1)
}
    80000d40:	60e2                	ld	ra,24(sp)
    80000d42:	6442                	ld	s0,16(sp)
    80000d44:	64a2                	ld	s1,8(sp)
    80000d46:	6105                	addi	sp,sp,32
    80000d48:	8082                	ret
    panic("acquire");
    80000d4a:	00007517          	auipc	a0,0x7
    80000d4e:	34e50513          	addi	a0,a0,846 # 80008098 <digits+0x58>
    80000d52:	fffff097          	auipc	ra,0xfffff
    80000d56:	7ec080e7          	jalr	2028(ra) # 8000053e <panic>

0000000080000d5a <pop_off>:

void
pop_off(void)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d62:	00001097          	auipc	ra,0x1
    80000d66:	e26080e7          	jalr	-474(ra) # 80001b88 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d6a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d6e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d70:	e78d                	bnez	a5,80000d9a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d72:	5d3c                	lw	a5,120(a0)
    80000d74:	02f05b63          	blez	a5,80000daa <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d78:	37fd                	addiw	a5,a5,-1
    80000d7a:	0007871b          	sext.w	a4,a5
    80000d7e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d80:	eb09                	bnez	a4,80000d92 <pop_off+0x38>
    80000d82:	5d7c                	lw	a5,124(a0)
    80000d84:	c799                	beqz	a5,80000d92 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d8e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d92:	60a2                	ld	ra,8(sp)
    80000d94:	6402                	ld	s0,0(sp)
    80000d96:	0141                	addi	sp,sp,16
    80000d98:	8082                	ret
    panic("pop_off - interruptible");
    80000d9a:	00007517          	auipc	a0,0x7
    80000d9e:	30650513          	addi	a0,a0,774 # 800080a0 <digits+0x60>
    80000da2:	fffff097          	auipc	ra,0xfffff
    80000da6:	79c080e7          	jalr	1948(ra) # 8000053e <panic>
    panic("pop_off");
    80000daa:	00007517          	auipc	a0,0x7
    80000dae:	30e50513          	addi	a0,a0,782 # 800080b8 <digits+0x78>
    80000db2:	fffff097          	auipc	ra,0xfffff
    80000db6:	78c080e7          	jalr	1932(ra) # 8000053e <panic>

0000000080000dba <release>:
{
    80000dba:	1101                	addi	sp,sp,-32
    80000dbc:	ec06                	sd	ra,24(sp)
    80000dbe:	e822                	sd	s0,16(sp)
    80000dc0:	e426                	sd	s1,8(sp)
    80000dc2:	1000                	addi	s0,sp,32
    80000dc4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dc6:	00000097          	auipc	ra,0x0
    80000dca:	ec6080e7          	jalr	-314(ra) # 80000c8c <holding>
    80000dce:	c115                	beqz	a0,80000df2 <release+0x38>
  lk->cpu = 0;
    80000dd0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dd4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dd8:	0f50000f          	fence	iorw,ow
    80000ddc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de0:	00000097          	auipc	ra,0x0
    80000de4:	f7a080e7          	jalr	-134(ra) # 80000d5a <pop_off>
}
    80000de8:	60e2                	ld	ra,24(sp)
    80000dea:	6442                	ld	s0,16(sp)
    80000dec:	64a2                	ld	s1,8(sp)
    80000dee:	6105                	addi	sp,sp,32
    80000df0:	8082                	ret
    panic("release");
    80000df2:	00007517          	auipc	a0,0x7
    80000df6:	2ce50513          	addi	a0,a0,718 # 800080c0 <digits+0x80>
    80000dfa:	fffff097          	auipc	ra,0xfffff
    80000dfe:	744080e7          	jalr	1860(ra) # 8000053e <panic>

0000000080000e02 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e02:	1141                	addi	sp,sp,-16
    80000e04:	e422                	sd	s0,8(sp)
    80000e06:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e08:	ca19                	beqz	a2,80000e1e <memset+0x1c>
    80000e0a:	87aa                	mv	a5,a0
    80000e0c:	1602                	slli	a2,a2,0x20
    80000e0e:	9201                	srli	a2,a2,0x20
    80000e10:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e14:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e18:	0785                	addi	a5,a5,1
    80000e1a:	fee79de3          	bne	a5,a4,80000e14 <memset+0x12>
  }
  return dst;
}
    80000e1e:	6422                	ld	s0,8(sp)
    80000e20:	0141                	addi	sp,sp,16
    80000e22:	8082                	ret

0000000080000e24 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e2a:	ca05                	beqz	a2,80000e5a <memcmp+0x36>
    80000e2c:	fff6069b          	addiw	a3,a2,-1
    80000e30:	1682                	slli	a3,a3,0x20
    80000e32:	9281                	srli	a3,a3,0x20
    80000e34:	0685                	addi	a3,a3,1
    80000e36:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e38:	00054783          	lbu	a5,0(a0)
    80000e3c:	0005c703          	lbu	a4,0(a1)
    80000e40:	00e79863          	bne	a5,a4,80000e50 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e44:	0505                	addi	a0,a0,1
    80000e46:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e48:	fed518e3          	bne	a0,a3,80000e38 <memcmp+0x14>
  }

  return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	a019                	j	80000e54 <memcmp+0x30>
      return *s1 - *s2;
    80000e50:	40e7853b          	subw	a0,a5,a4
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret
  return 0;
    80000e5a:	4501                	li	a0,0
    80000e5c:	bfe5                	j	80000e54 <memcmp+0x30>

0000000080000e5e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e5e:	1141                	addi	sp,sp,-16
    80000e60:	e422                	sd	s0,8(sp)
    80000e62:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000e64:	c205                	beqz	a2,80000e84 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e66:	02a5e263          	bltu	a1,a0,80000e8a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e6a:	1602                	slli	a2,a2,0x20
    80000e6c:	9201                	srli	a2,a2,0x20
    80000e6e:	00c587b3          	add	a5,a1,a2
{
    80000e72:	872a                	mv	a4,a0
      *d++ = *s++;
    80000e74:	0585                	addi	a1,a1,1
    80000e76:	0705                	addi	a4,a4,1
    80000e78:	fff5c683          	lbu	a3,-1(a1)
    80000e7c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000e80:	fef59ae3          	bne	a1,a5,80000e74 <memmove+0x16>

  return dst;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  if(s < d && s + n > d){
    80000e8a:	02061693          	slli	a3,a2,0x20
    80000e8e:	9281                	srli	a3,a3,0x20
    80000e90:	00d58733          	add	a4,a1,a3
    80000e94:	fce57be3          	bgeu	a0,a4,80000e6a <memmove+0xc>
    d += n;
    80000e98:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000e9a:	fff6079b          	addiw	a5,a2,-1
    80000e9e:	1782                	slli	a5,a5,0x20
    80000ea0:	9381                	srli	a5,a5,0x20
    80000ea2:	fff7c793          	not	a5,a5
    80000ea6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ea8:	177d                	addi	a4,a4,-1
    80000eaa:	16fd                	addi	a3,a3,-1
    80000eac:	00074603          	lbu	a2,0(a4)
    80000eb0:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000eb4:	fee79ae3          	bne	a5,a4,80000ea8 <memmove+0x4a>
    80000eb8:	b7f1                	j	80000e84 <memmove+0x26>

0000000080000eba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000eba:	1141                	addi	sp,sp,-16
    80000ebc:	e406                	sd	ra,8(sp)
    80000ebe:	e022                	sd	s0,0(sp)
    80000ec0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	f9c080e7          	jalr	-100(ra) # 80000e5e <memmove>
}
    80000eca:	60a2                	ld	ra,8(sp)
    80000ecc:	6402                	ld	s0,0(sp)
    80000ece:	0141                	addi	sp,sp,16
    80000ed0:	8082                	ret

0000000080000ed2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e422                	sd	s0,8(sp)
    80000ed6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ed8:	ce11                	beqz	a2,80000ef4 <strncmp+0x22>
    80000eda:	00054783          	lbu	a5,0(a0)
    80000ede:	cf89                	beqz	a5,80000ef8 <strncmp+0x26>
    80000ee0:	0005c703          	lbu	a4,0(a1)
    80000ee4:	00f71a63          	bne	a4,a5,80000ef8 <strncmp+0x26>
    n--, p++, q++;
    80000ee8:	367d                	addiw	a2,a2,-1
    80000eea:	0505                	addi	a0,a0,1
    80000eec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eee:	f675                	bnez	a2,80000eda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ef0:	4501                	li	a0,0
    80000ef2:	a809                	j	80000f04 <strncmp+0x32>
    80000ef4:	4501                	li	a0,0
    80000ef6:	a039                	j	80000f04 <strncmp+0x32>
  if(n == 0)
    80000ef8:	ca09                	beqz	a2,80000f0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000efa:	00054503          	lbu	a0,0(a0)
    80000efe:	0005c783          	lbu	a5,0(a1)
    80000f02:	9d1d                	subw	a0,a0,a5
}
    80000f04:	6422                	ld	s0,8(sp)
    80000f06:	0141                	addi	sp,sp,16
    80000f08:	8082                	ret
    return 0;
    80000f0a:	4501                	li	a0,0
    80000f0c:	bfe5                	j	80000f04 <strncmp+0x32>

0000000080000f0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f0e:	1141                	addi	sp,sp,-16
    80000f10:	e422                	sd	s0,8(sp)
    80000f12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f14:	872a                	mv	a4,a0
    80000f16:	8832                	mv	a6,a2
    80000f18:	367d                	addiw	a2,a2,-1
    80000f1a:	01005963          	blez	a6,80000f2c <strncpy+0x1e>
    80000f1e:	0705                	addi	a4,a4,1
    80000f20:	0005c783          	lbu	a5,0(a1)
    80000f24:	fef70fa3          	sb	a5,-1(a4)
    80000f28:	0585                	addi	a1,a1,1
    80000f2a:	f7f5                	bnez	a5,80000f16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f2c:	86ba                	mv	a3,a4
    80000f2e:	00c05c63          	blez	a2,80000f46 <strncpy+0x38>
    *s++ = 0;
    80000f32:	0685                	addi	a3,a3,1
    80000f34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f38:	fff6c793          	not	a5,a3
    80000f3c:	9fb9                	addw	a5,a5,a4
    80000f3e:	010787bb          	addw	a5,a5,a6
    80000f42:	fef048e3          	bgtz	a5,80000f32 <strncpy+0x24>
  return os;
}
    80000f46:	6422                	ld	s0,8(sp)
    80000f48:	0141                	addi	sp,sp,16
    80000f4a:	8082                	ret

0000000080000f4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f4c:	1141                	addi	sp,sp,-16
    80000f4e:	e422                	sd	s0,8(sp)
    80000f50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f52:	02c05363          	blez	a2,80000f78 <safestrcpy+0x2c>
    80000f56:	fff6069b          	addiw	a3,a2,-1
    80000f5a:	1682                	slli	a3,a3,0x20
    80000f5c:	9281                	srli	a3,a3,0x20
    80000f5e:	96ae                	add	a3,a3,a1
    80000f60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f62:	00d58963          	beq	a1,a3,80000f74 <safestrcpy+0x28>
    80000f66:	0585                	addi	a1,a1,1
    80000f68:	0785                	addi	a5,a5,1
    80000f6a:	fff5c703          	lbu	a4,-1(a1)
    80000f6e:	fee78fa3          	sb	a4,-1(a5)
    80000f72:	fb65                	bnez	a4,80000f62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f78:	6422                	ld	s0,8(sp)
    80000f7a:	0141                	addi	sp,sp,16
    80000f7c:	8082                	ret

0000000080000f7e <strlen>:

int
strlen(const char *s)
{
    80000f7e:	1141                	addi	sp,sp,-16
    80000f80:	e422                	sd	s0,8(sp)
    80000f82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f84:	00054783          	lbu	a5,0(a0)
    80000f88:	cf91                	beqz	a5,80000fa4 <strlen+0x26>
    80000f8a:	0505                	addi	a0,a0,1
    80000f8c:	87aa                	mv	a5,a0
    80000f8e:	4685                	li	a3,1
    80000f90:	9e89                	subw	a3,a3,a0
    80000f92:	00f6853b          	addw	a0,a3,a5
    80000f96:	0785                	addi	a5,a5,1
    80000f98:	fff7c703          	lbu	a4,-1(a5)
    80000f9c:	fb7d                	bnez	a4,80000f92 <strlen+0x14>
    ;
  return n;
}
    80000f9e:	6422                	ld	s0,8(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fa4:	4501                	li	a0,0
    80000fa6:	bfe5                	j	80000f9e <strlen+0x20>

0000000080000fa8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e406                	sd	ra,8(sp)
    80000fac:	e022                	sd	s0,0(sp)
    80000fae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	bc8080e7          	jalr	-1080(ra) # 80001b78 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fb8:	00008717          	auipc	a4,0x8
    80000fbc:	96070713          	addi	a4,a4,-1696 # 80008918 <started>
  if(cpuid() == 0){
    80000fc0:	c139                	beqz	a0,80001006 <main+0x5e>
    while(started == 0)
    80000fc2:	431c                	lw	a5,0(a4)
    80000fc4:	2781                	sext.w	a5,a5
    80000fc6:	dff5                	beqz	a5,80000fc2 <main+0x1a>
      ;
    __sync_synchronize();
    80000fc8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	bac080e7          	jalr	-1108(ra) # 80001b78 <cpuid>
    80000fd4:	85aa                	mv	a1,a0
    80000fd6:	00007517          	auipc	a0,0x7
    80000fda:	10a50513          	addi	a0,a0,266 # 800080e0 <digits+0xa0>
    80000fde:	fffff097          	auipc	ra,0xfffff
    80000fe2:	5aa080e7          	jalr	1450(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000fe6:	00000097          	auipc	ra,0x0
    80000fea:	0d8080e7          	jalr	216(ra) # 800010be <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fee:	00002097          	auipc	ra,0x2
    80000ff2:	cea080e7          	jalr	-790(ra) # 80002cd8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ff6:	00005097          	auipc	ra,0x5
    80000ffa:	4ba080e7          	jalr	1210(ra) # 800064b0 <plicinithart>
  }

  scheduler();        
    80000ffe:	00001097          	auipc	ra,0x1
    80001002:	0d6080e7          	jalr	214(ra) # 800020d4 <scheduler>
    consoleinit();
    80001006:	fffff097          	auipc	ra,0xfffff
    8000100a:	44a080e7          	jalr	1098(ra) # 80000450 <consoleinit>
    printfinit();
    8000100e:	fffff097          	auipc	ra,0xfffff
    80001012:	75a080e7          	jalr	1882(ra) # 80000768 <printfinit>
    printf("\n");
    80001016:	00007517          	auipc	a0,0x7
    8000101a:	2b250513          	addi	a0,a0,690 # 800082c8 <digits+0x288>
    8000101e:	fffff097          	auipc	ra,0xfffff
    80001022:	56a080e7          	jalr	1386(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0a250513          	addi	a0,a0,162 # 800080c8 <digits+0x88>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	55a080e7          	jalr	1370(ra) # 80000588 <printf>
    printf("\n");
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	29250513          	addi	a0,a0,658 # 800082c8 <digits+0x288>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	54a080e7          	jalr	1354(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001046:	00000097          	auipc	ra,0x0
    8000104a:	b04080e7          	jalr	-1276(ra) # 80000b4a <kinit>
    kvminit();       // create kernel page table
    8000104e:	00000097          	auipc	ra,0x0
    80001052:	326080e7          	jalr	806(ra) # 80001374 <kvminit>
    kvminithart();   // turn on paging
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	068080e7          	jalr	104(ra) # 800010be <kvminithart>
    procinit();      // process table
    8000105e:	00001097          	auipc	ra,0x1
    80001062:	a66080e7          	jalr	-1434(ra) # 80001ac4 <procinit>
    trapinit();      // trap vectors
    80001066:	00002097          	auipc	ra,0x2
    8000106a:	c4a080e7          	jalr	-950(ra) # 80002cb0 <trapinit>
    trapinithart();  // install kernel trap vector
    8000106e:	00002097          	auipc	ra,0x2
    80001072:	c6a080e7          	jalr	-918(ra) # 80002cd8 <trapinithart>
    plicinit();      // set up interrupt controller
    80001076:	00005097          	auipc	ra,0x5
    8000107a:	424080e7          	jalr	1060(ra) # 8000649a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000107e:	00005097          	auipc	ra,0x5
    80001082:	432080e7          	jalr	1074(ra) # 800064b0 <plicinithart>
    binit();         // buffer cache
    80001086:	00002097          	auipc	ra,0x2
    8000108a:	5b6080e7          	jalr	1462(ra) # 8000363c <binit>
    iinit();         // inode table
    8000108e:	00003097          	auipc	ra,0x3
    80001092:	c5a080e7          	jalr	-934(ra) # 80003ce8 <iinit>
    fileinit();      // file table
    80001096:	00004097          	auipc	ra,0x4
    8000109a:	bf8080e7          	jalr	-1032(ra) # 80004c8e <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000109e:	00005097          	auipc	ra,0x5
    800010a2:	51a080e7          	jalr	1306(ra) # 800065b8 <virtio_disk_init>
    userinit();      // first user process
    800010a6:	00001097          	auipc	ra,0x1
    800010aa:	e10080e7          	jalr	-496(ra) # 80001eb6 <userinit>
    __sync_synchronize();
    800010ae:	0ff0000f          	fence
    started = 1;
    800010b2:	4785                	li	a5,1
    800010b4:	00008717          	auipc	a4,0x8
    800010b8:	86f72223          	sw	a5,-1948(a4) # 80008918 <started>
    800010bc:	b789                	j	80000ffe <main+0x56>

00000000800010be <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010be:	1141                	addi	sp,sp,-16
    800010c0:	e422                	sd	s0,8(sp)
    800010c2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010c4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    800010c8:	00008797          	auipc	a5,0x8
    800010cc:	8587b783          	ld	a5,-1960(a5) # 80008920 <kernel_pagetable>
    800010d0:	83b1                	srli	a5,a5,0xc
    800010d2:	577d                	li	a4,-1
    800010d4:	177e                	slli	a4,a4,0x3f
    800010d6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010d8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800010dc:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800010e0:	6422                	ld	s0,8(sp)
    800010e2:	0141                	addi	sp,sp,16
    800010e4:	8082                	ret

00000000800010e6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010e6:	7139                	addi	sp,sp,-64
    800010e8:	fc06                	sd	ra,56(sp)
    800010ea:	f822                	sd	s0,48(sp)
    800010ec:	f426                	sd	s1,40(sp)
    800010ee:	f04a                	sd	s2,32(sp)
    800010f0:	ec4e                	sd	s3,24(sp)
    800010f2:	e852                	sd	s4,16(sp)
    800010f4:	e456                	sd	s5,8(sp)
    800010f6:	e05a                	sd	s6,0(sp)
    800010f8:	0080                	addi	s0,sp,64
    800010fa:	84aa                	mv	s1,a0
    800010fc:	89ae                	mv	s3,a1
    800010fe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001100:	57fd                	li	a5,-1
    80001102:	83e9                	srli	a5,a5,0x1a
    80001104:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001106:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001108:	04b7f263          	bgeu	a5,a1,8000114c <walk+0x66>
    panic("walk");
    8000110c:	00007517          	auipc	a0,0x7
    80001110:	fec50513          	addi	a0,a0,-20 # 800080f8 <digits+0xb8>
    80001114:	fffff097          	auipc	ra,0xfffff
    80001118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000111c:	060a8663          	beqz	s5,80001188 <walk+0xa2>
    80001120:	00000097          	auipc	ra,0x0
    80001124:	ab8080e7          	jalr	-1352(ra) # 80000bd8 <kalloc>
    80001128:	84aa                	mv	s1,a0
    8000112a:	c529                	beqz	a0,80001174 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000112c:	6605                	lui	a2,0x1
    8000112e:	4581                	li	a1,0
    80001130:	00000097          	auipc	ra,0x0
    80001134:	cd2080e7          	jalr	-814(ra) # 80000e02 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001138:	00c4d793          	srli	a5,s1,0xc
    8000113c:	07aa                	slli	a5,a5,0xa
    8000113e:	0017e793          	ori	a5,a5,1
    80001142:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001146:	3a5d                	addiw	s4,s4,-9
    80001148:	036a0063          	beq	s4,s6,80001168 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000114c:	0149d933          	srl	s2,s3,s4
    80001150:	1ff97913          	andi	s2,s2,511
    80001154:	090e                	slli	s2,s2,0x3
    80001156:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001158:	00093483          	ld	s1,0(s2)
    8000115c:	0014f793          	andi	a5,s1,1
    80001160:	dfd5                	beqz	a5,8000111c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001162:	80a9                	srli	s1,s1,0xa
    80001164:	04b2                	slli	s1,s1,0xc
    80001166:	b7c5                	j	80001146 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001168:	00c9d513          	srli	a0,s3,0xc
    8000116c:	1ff57513          	andi	a0,a0,511
    80001170:	050e                	slli	a0,a0,0x3
    80001172:	9526                	add	a0,a0,s1
}
    80001174:	70e2                	ld	ra,56(sp)
    80001176:	7442                	ld	s0,48(sp)
    80001178:	74a2                	ld	s1,40(sp)
    8000117a:	7902                	ld	s2,32(sp)
    8000117c:	69e2                	ld	s3,24(sp)
    8000117e:	6a42                	ld	s4,16(sp)
    80001180:	6aa2                	ld	s5,8(sp)
    80001182:	6b02                	ld	s6,0(sp)
    80001184:	6121                	addi	sp,sp,64
    80001186:	8082                	ret
        return 0;
    80001188:	4501                	li	a0,0
    8000118a:	b7ed                	j	80001174 <walk+0x8e>

000000008000118c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000118c:	57fd                	li	a5,-1
    8000118e:	83e9                	srli	a5,a5,0x1a
    80001190:	00b7f463          	bgeu	a5,a1,80001198 <walkaddr+0xc>
    return 0;
    80001194:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001196:	8082                	ret
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011a0:	4601                	li	a2,0
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	f44080e7          	jalr	-188(ra) # 800010e6 <walk>
  if(pte == 0)
    800011aa:	c105                	beqz	a0,800011ca <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011ac:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011ae:	0117f693          	andi	a3,a5,17
    800011b2:	4745                	li	a4,17
    return 0;
    800011b4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011b6:	00e68663          	beq	a3,a4,800011c2 <walkaddr+0x36>
}
    800011ba:	60a2                	ld	ra,8(sp)
    800011bc:	6402                	ld	s0,0(sp)
    800011be:	0141                	addi	sp,sp,16
    800011c0:	8082                	ret
  pa = PTE2PA(*pte);
    800011c2:	00a7d513          	srli	a0,a5,0xa
    800011c6:	0532                	slli	a0,a0,0xc
  return pa;
    800011c8:	bfcd                	j	800011ba <walkaddr+0x2e>
    return 0;
    800011ca:	4501                	li	a0,0
    800011cc:	b7fd                	j	800011ba <walkaddr+0x2e>

00000000800011ce <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ce:	715d                	addi	sp,sp,-80
    800011d0:	e486                	sd	ra,72(sp)
    800011d2:	e0a2                	sd	s0,64(sp)
    800011d4:	fc26                	sd	s1,56(sp)
    800011d6:	f84a                	sd	s2,48(sp)
    800011d8:	f44e                	sd	s3,40(sp)
    800011da:	f052                	sd	s4,32(sp)
    800011dc:	ec56                	sd	s5,24(sp)
    800011de:	e85a                	sd	s6,16(sp)
    800011e0:	e45e                	sd	s7,8(sp)
    800011e2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800011e4:	c639                	beqz	a2,80001232 <mappages+0x64>
    800011e6:	8aaa                	mv	s5,a0
    800011e8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800011ea:	77fd                	lui	a5,0xfffff
    800011ec:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800011f0:	15fd                	addi	a1,a1,-1
    800011f2:	00c589b3          	add	s3,a1,a2
    800011f6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800011fa:	8952                	mv	s2,s4
    800011fc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001200:	6b85                	lui	s7,0x1
    80001202:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001206:	4605                	li	a2,1
    80001208:	85ca                	mv	a1,s2
    8000120a:	8556                	mv	a0,s5
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	eda080e7          	jalr	-294(ra) # 800010e6 <walk>
    80001214:	cd1d                	beqz	a0,80001252 <mappages+0x84>
    if(*pte & PTE_V)
    80001216:	611c                	ld	a5,0(a0)
    80001218:	8b85                	andi	a5,a5,1
    8000121a:	e785                	bnez	a5,80001242 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000121c:	80b1                	srli	s1,s1,0xc
    8000121e:	04aa                	slli	s1,s1,0xa
    80001220:	0164e4b3          	or	s1,s1,s6
    80001224:	0014e493          	ori	s1,s1,1
    80001228:	e104                	sd	s1,0(a0)
    if(a == last)
    8000122a:	05390063          	beq	s2,s3,8000126a <mappages+0x9c>
    a += PGSIZE;
    8000122e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001230:	bfc9                	j	80001202 <mappages+0x34>
    panic("mappages: size");
    80001232:	00007517          	auipc	a0,0x7
    80001236:	ece50513          	addi	a0,a0,-306 # 80008100 <digits+0xc0>
    8000123a:	fffff097          	auipc	ra,0xfffff
    8000123e:	304080e7          	jalr	772(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001242:	00007517          	auipc	a0,0x7
    80001246:	ece50513          	addi	a0,a0,-306 # 80008110 <digits+0xd0>
    8000124a:	fffff097          	auipc	ra,0xfffff
    8000124e:	2f4080e7          	jalr	756(ra) # 8000053e <panic>
      return -1;
    80001252:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001254:	60a6                	ld	ra,72(sp)
    80001256:	6406                	ld	s0,64(sp)
    80001258:	74e2                	ld	s1,56(sp)
    8000125a:	7942                	ld	s2,48(sp)
    8000125c:	79a2                	ld	s3,40(sp)
    8000125e:	7a02                	ld	s4,32(sp)
    80001260:	6ae2                	ld	s5,24(sp)
    80001262:	6b42                	ld	s6,16(sp)
    80001264:	6ba2                	ld	s7,8(sp)
    80001266:	6161                	addi	sp,sp,80
    80001268:	8082                	ret
  return 0;
    8000126a:	4501                	li	a0,0
    8000126c:	b7e5                	j	80001254 <mappages+0x86>

000000008000126e <kvmmap>:
{
    8000126e:	1141                	addi	sp,sp,-16
    80001270:	e406                	sd	ra,8(sp)
    80001272:	e022                	sd	s0,0(sp)
    80001274:	0800                	addi	s0,sp,16
    80001276:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001278:	86b2                	mv	a3,a2
    8000127a:	863e                	mv	a2,a5
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f52080e7          	jalr	-174(ra) # 800011ce <mappages>
    80001284:	e509                	bnez	a0,8000128e <kvmmap+0x20>
}
    80001286:	60a2                	ld	ra,8(sp)
    80001288:	6402                	ld	s0,0(sp)
    8000128a:	0141                	addi	sp,sp,16
    8000128c:	8082                	ret
    panic("kvmmap");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e9250513          	addi	a0,a0,-366 # 80008120 <digits+0xe0>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2a8080e7          	jalr	680(ra) # 8000053e <panic>

000000008000129e <kvmmake>:
{
    8000129e:	1101                	addi	sp,sp,-32
    800012a0:	ec06                	sd	ra,24(sp)
    800012a2:	e822                	sd	s0,16(sp)
    800012a4:	e426                	sd	s1,8(sp)
    800012a6:	e04a                	sd	s2,0(sp)
    800012a8:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	92e080e7          	jalr	-1746(ra) # 80000bd8 <kalloc>
    800012b2:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012b4:	6605                	lui	a2,0x1
    800012b6:	4581                	li	a1,0
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	b4a080e7          	jalr	-1206(ra) # 80000e02 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c0:	4719                	li	a4,6
    800012c2:	6685                	lui	a3,0x1
    800012c4:	10000637          	lui	a2,0x10000
    800012c8:	100005b7          	lui	a1,0x10000
    800012cc:	8526                	mv	a0,s1
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	fa0080e7          	jalr	-96(ra) # 8000126e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012d6:	4719                	li	a4,6
    800012d8:	6685                	lui	a3,0x1
    800012da:	10001637          	lui	a2,0x10001
    800012de:	100015b7          	lui	a1,0x10001
    800012e2:	8526                	mv	a0,s1
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f8a080e7          	jalr	-118(ra) # 8000126e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ec:	4719                	li	a4,6
    800012ee:	004006b7          	lui	a3,0x400
    800012f2:	0c000637          	lui	a2,0xc000
    800012f6:	0c0005b7          	lui	a1,0xc000
    800012fa:	8526                	mv	a0,s1
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f72080e7          	jalr	-142(ra) # 8000126e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001304:	00007917          	auipc	s2,0x7
    80001308:	cfc90913          	addi	s2,s2,-772 # 80008000 <etext>
    8000130c:	4729                	li	a4,10
    8000130e:	80007697          	auipc	a3,0x80007
    80001312:	cf268693          	addi	a3,a3,-782 # 8000 <_entry-0x7fff8000>
    80001316:	4605                	li	a2,1
    80001318:	067e                	slli	a2,a2,0x1f
    8000131a:	85b2                	mv	a1,a2
    8000131c:	8526                	mv	a0,s1
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	f50080e7          	jalr	-176(ra) # 8000126e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001326:	4719                	li	a4,6
    80001328:	46c5                	li	a3,17
    8000132a:	06ee                	slli	a3,a3,0x1b
    8000132c:	412686b3          	sub	a3,a3,s2
    80001330:	864a                	mv	a2,s2
    80001332:	85ca                	mv	a1,s2
    80001334:	8526                	mv	a0,s1
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	f38080e7          	jalr	-200(ra) # 8000126e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000133e:	4729                	li	a4,10
    80001340:	6685                	lui	a3,0x1
    80001342:	00006617          	auipc	a2,0x6
    80001346:	cbe60613          	addi	a2,a2,-834 # 80007000 <_trampoline>
    8000134a:	040005b7          	lui	a1,0x4000
    8000134e:	15fd                	addi	a1,a1,-1
    80001350:	05b2                	slli	a1,a1,0xc
    80001352:	8526                	mv	a0,s1
    80001354:	00000097          	auipc	ra,0x0
    80001358:	f1a080e7          	jalr	-230(ra) # 8000126e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000135c:	8526                	mv	a0,s1
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	6d0080e7          	jalr	1744(ra) # 80001a2e <proc_mapstacks>
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6902                	ld	s2,0(sp)
    80001370:	6105                	addi	sp,sp,32
    80001372:	8082                	ret

0000000080001374 <kvminit>:
{
    80001374:	1141                	addi	sp,sp,-16
    80001376:	e406                	sd	ra,8(sp)
    80001378:	e022                	sd	s0,0(sp)
    8000137a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000137c:	00000097          	auipc	ra,0x0
    80001380:	f22080e7          	jalr	-222(ra) # 8000129e <kvmmake>
    80001384:	00007797          	auipc	a5,0x7
    80001388:	58a7be23          	sd	a0,1436(a5) # 80008920 <kernel_pagetable>
}
    8000138c:	60a2                	ld	ra,8(sp)
    8000138e:	6402                	ld	s0,0(sp)
    80001390:	0141                	addi	sp,sp,16
    80001392:	8082                	ret

0000000080001394 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001394:	715d                	addi	sp,sp,-80
    80001396:	e486                	sd	ra,72(sp)
    80001398:	e0a2                	sd	s0,64(sp)
    8000139a:	fc26                	sd	s1,56(sp)
    8000139c:	f84a                	sd	s2,48(sp)
    8000139e:	f44e                	sd	s3,40(sp)
    800013a0:	f052                	sd	s4,32(sp)
    800013a2:	ec56                	sd	s5,24(sp)
    800013a4:	e85a                	sd	s6,16(sp)
    800013a6:	e45e                	sd	s7,8(sp)
    800013a8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013aa:	03459793          	slli	a5,a1,0x34
    800013ae:	e795                	bnez	a5,800013da <uvmunmap+0x46>
    800013b0:	8a2a                	mv	s4,a0
    800013b2:	892e                	mv	s2,a1
    800013b4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013b6:	0632                	slli	a2,a2,0xc
    800013b8:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013bc:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	6b05                	lui	s6,0x1
    800013c0:	0735e263          	bltu	a1,s3,80001424 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013c4:	60a6                	ld	ra,72(sp)
    800013c6:	6406                	ld	s0,64(sp)
    800013c8:	74e2                	ld	s1,56(sp)
    800013ca:	7942                	ld	s2,48(sp)
    800013cc:	79a2                	ld	s3,40(sp)
    800013ce:	7a02                	ld	s4,32(sp)
    800013d0:	6ae2                	ld	s5,24(sp)
    800013d2:	6b42                	ld	s6,16(sp)
    800013d4:	6ba2                	ld	s7,8(sp)
    800013d6:	6161                	addi	sp,sp,80
    800013d8:	8082                	ret
    panic("uvmunmap: not aligned");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d4e50513          	addi	a0,a0,-690 # 80008128 <digits+0xe8>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800013ea:	00007517          	auipc	a0,0x7
    800013ee:	d5650513          	addi	a0,a0,-682 # 80008140 <digits+0x100>
    800013f2:	fffff097          	auipc	ra,0xfffff
    800013f6:	14c080e7          	jalr	332(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800013fa:	00007517          	auipc	a0,0x7
    800013fe:	d5650513          	addi	a0,a0,-682 # 80008150 <digits+0x110>
    80001402:	fffff097          	auipc	ra,0xfffff
    80001406:	13c080e7          	jalr	316(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    8000140a:	00007517          	auipc	a0,0x7
    8000140e:	d5e50513          	addi	a0,a0,-674 # 80008168 <digits+0x128>
    80001412:	fffff097          	auipc	ra,0xfffff
    80001416:	12c080e7          	jalr	300(ra) # 8000053e <panic>
    *pte = 0;
    8000141a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000141e:	995a                	add	s2,s2,s6
    80001420:	fb3972e3          	bgeu	s2,s3,800013c4 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001424:	4601                	li	a2,0
    80001426:	85ca                	mv	a1,s2
    80001428:	8552                	mv	a0,s4
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	cbc080e7          	jalr	-836(ra) # 800010e6 <walk>
    80001432:	84aa                	mv	s1,a0
    80001434:	d95d                	beqz	a0,800013ea <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001436:	6108                	ld	a0,0(a0)
    80001438:	00157793          	andi	a5,a0,1
    8000143c:	dfdd                	beqz	a5,800013fa <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000143e:	3ff57793          	andi	a5,a0,1023
    80001442:	fd7784e3          	beq	a5,s7,8000140a <uvmunmap+0x76>
    if(do_free){
    80001446:	fc0a8ae3          	beqz	s5,8000141a <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000144a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000144c:	0532                	slli	a0,a0,0xc
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	59c080e7          	jalr	1436(ra) # 800009ea <kfree>
    80001456:	b7d1                	j	8000141a <uvmunmap+0x86>

0000000080001458 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001458:	1101                	addi	sp,sp,-32
    8000145a:	ec06                	sd	ra,24(sp)
    8000145c:	e822                	sd	s0,16(sp)
    8000145e:	e426                	sd	s1,8(sp)
    80001460:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001462:	fffff097          	auipc	ra,0xfffff
    80001466:	776080e7          	jalr	1910(ra) # 80000bd8 <kalloc>
    8000146a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000146c:	c519                	beqz	a0,8000147a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000146e:	6605                	lui	a2,0x1
    80001470:	4581                	li	a1,0
    80001472:	00000097          	auipc	ra,0x0
    80001476:	990080e7          	jalr	-1648(ra) # 80000e02 <memset>
  return pagetable;
}
    8000147a:	8526                	mv	a0,s1
    8000147c:	60e2                	ld	ra,24(sp)
    8000147e:	6442                	ld	s0,16(sp)
    80001480:	64a2                	ld	s1,8(sp)
    80001482:	6105                	addi	sp,sp,32
    80001484:	8082                	ret

0000000080001486 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001486:	7179                	addi	sp,sp,-48
    80001488:	f406                	sd	ra,40(sp)
    8000148a:	f022                	sd	s0,32(sp)
    8000148c:	ec26                	sd	s1,24(sp)
    8000148e:	e84a                	sd	s2,16(sp)
    80001490:	e44e                	sd	s3,8(sp)
    80001492:	e052                	sd	s4,0(sp)
    80001494:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001496:	6785                	lui	a5,0x1
    80001498:	04f67863          	bgeu	a2,a5,800014e8 <uvmfirst+0x62>
    8000149c:	8a2a                	mv	s4,a0
    8000149e:	89ae                	mv	s3,a1
    800014a0:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	736080e7          	jalr	1846(ra) # 80000bd8 <kalloc>
    800014aa:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014ac:	6605                	lui	a2,0x1
    800014ae:	4581                	li	a1,0
    800014b0:	00000097          	auipc	ra,0x0
    800014b4:	952080e7          	jalr	-1710(ra) # 80000e02 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014b8:	4779                	li	a4,30
    800014ba:	86ca                	mv	a3,s2
    800014bc:	6605                	lui	a2,0x1
    800014be:	4581                	li	a1,0
    800014c0:	8552                	mv	a0,s4
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	d0c080e7          	jalr	-756(ra) # 800011ce <mappages>
  memmove(mem, src, sz);
    800014ca:	8626                	mv	a2,s1
    800014cc:	85ce                	mv	a1,s3
    800014ce:	854a                	mv	a0,s2
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	98e080e7          	jalr	-1650(ra) # 80000e5e <memmove>
}
    800014d8:	70a2                	ld	ra,40(sp)
    800014da:	7402                	ld	s0,32(sp)
    800014dc:	64e2                	ld	s1,24(sp)
    800014de:	6942                	ld	s2,16(sp)
    800014e0:	69a2                	ld	s3,8(sp)
    800014e2:	6a02                	ld	s4,0(sp)
    800014e4:	6145                	addi	sp,sp,48
    800014e6:	8082                	ret
    panic("uvmfirst: more than a page");
    800014e8:	00007517          	auipc	a0,0x7
    800014ec:	c9850513          	addi	a0,a0,-872 # 80008180 <digits+0x140>
    800014f0:	fffff097          	auipc	ra,0xfffff
    800014f4:	04e080e7          	jalr	78(ra) # 8000053e <panic>

00000000800014f8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014f8:	1101                	addi	sp,sp,-32
    800014fa:	ec06                	sd	ra,24(sp)
    800014fc:	e822                	sd	s0,16(sp)
    800014fe:	e426                	sd	s1,8(sp)
    80001500:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001502:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001504:	00b67d63          	bgeu	a2,a1,8000151e <uvmdealloc+0x26>
    80001508:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000150a:	6785                	lui	a5,0x1
    8000150c:	17fd                	addi	a5,a5,-1
    8000150e:	00f60733          	add	a4,a2,a5
    80001512:	767d                	lui	a2,0xfffff
    80001514:	8f71                	and	a4,a4,a2
    80001516:	97ae                	add	a5,a5,a1
    80001518:	8ff1                	and	a5,a5,a2
    8000151a:	00f76863          	bltu	a4,a5,8000152a <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000151e:	8526                	mv	a0,s1
    80001520:	60e2                	ld	ra,24(sp)
    80001522:	6442                	ld	s0,16(sp)
    80001524:	64a2                	ld	s1,8(sp)
    80001526:	6105                	addi	sp,sp,32
    80001528:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000152a:	8f99                	sub	a5,a5,a4
    8000152c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000152e:	4685                	li	a3,1
    80001530:	0007861b          	sext.w	a2,a5
    80001534:	85ba                	mv	a1,a4
    80001536:	00000097          	auipc	ra,0x0
    8000153a:	e5e080e7          	jalr	-418(ra) # 80001394 <uvmunmap>
    8000153e:	b7c5                	j	8000151e <uvmdealloc+0x26>

0000000080001540 <uvmalloc>:
  if(newsz < oldsz)
    80001540:	0ab66563          	bltu	a2,a1,800015ea <uvmalloc+0xaa>
{
    80001544:	7139                	addi	sp,sp,-64
    80001546:	fc06                	sd	ra,56(sp)
    80001548:	f822                	sd	s0,48(sp)
    8000154a:	f426                	sd	s1,40(sp)
    8000154c:	f04a                	sd	s2,32(sp)
    8000154e:	ec4e                	sd	s3,24(sp)
    80001550:	e852                	sd	s4,16(sp)
    80001552:	e456                	sd	s5,8(sp)
    80001554:	e05a                	sd	s6,0(sp)
    80001556:	0080                	addi	s0,sp,64
    80001558:	8aaa                	mv	s5,a0
    8000155a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000155c:	6985                	lui	s3,0x1
    8000155e:	19fd                	addi	s3,s3,-1
    80001560:	95ce                	add	a1,a1,s3
    80001562:	79fd                	lui	s3,0xfffff
    80001564:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001568:	08c9f363          	bgeu	s3,a2,800015ee <uvmalloc+0xae>
    8000156c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000156e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	666080e7          	jalr	1638(ra) # 80000bd8 <kalloc>
    8000157a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000157c:	c51d                	beqz	a0,800015aa <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000157e:	6605                	lui	a2,0x1
    80001580:	4581                	li	a1,0
    80001582:	00000097          	auipc	ra,0x0
    80001586:	880080e7          	jalr	-1920(ra) # 80000e02 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000158a:	875a                	mv	a4,s6
    8000158c:	86a6                	mv	a3,s1
    8000158e:	6605                	lui	a2,0x1
    80001590:	85ca                	mv	a1,s2
    80001592:	8556                	mv	a0,s5
    80001594:	00000097          	auipc	ra,0x0
    80001598:	c3a080e7          	jalr	-966(ra) # 800011ce <mappages>
    8000159c:	e90d                	bnez	a0,800015ce <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000159e:	6785                	lui	a5,0x1
    800015a0:	993e                	add	s2,s2,a5
    800015a2:	fd4968e3          	bltu	s2,s4,80001572 <uvmalloc+0x32>
  return newsz;
    800015a6:	8552                	mv	a0,s4
    800015a8:	a809                	j	800015ba <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015aa:	864e                	mv	a2,s3
    800015ac:	85ca                	mv	a1,s2
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f48080e7          	jalr	-184(ra) # 800014f8 <uvmdealloc>
      return 0;
    800015b8:	4501                	li	a0,0
}
    800015ba:	70e2                	ld	ra,56(sp)
    800015bc:	7442                	ld	s0,48(sp)
    800015be:	74a2                	ld	s1,40(sp)
    800015c0:	7902                	ld	s2,32(sp)
    800015c2:	69e2                	ld	s3,24(sp)
    800015c4:	6a42                	ld	s4,16(sp)
    800015c6:	6aa2                	ld	s5,8(sp)
    800015c8:	6b02                	ld	s6,0(sp)
    800015ca:	6121                	addi	sp,sp,64
    800015cc:	8082                	ret
      kfree(mem);
    800015ce:	8526                	mv	a0,s1
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	41a080e7          	jalr	1050(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015d8:	864e                	mv	a2,s3
    800015da:	85ca                	mv	a1,s2
    800015dc:	8556                	mv	a0,s5
    800015de:	00000097          	auipc	ra,0x0
    800015e2:	f1a080e7          	jalr	-230(ra) # 800014f8 <uvmdealloc>
      return 0;
    800015e6:	4501                	li	a0,0
    800015e8:	bfc9                	j	800015ba <uvmalloc+0x7a>
    return oldsz;
    800015ea:	852e                	mv	a0,a1
}
    800015ec:	8082                	ret
  return newsz;
    800015ee:	8532                	mv	a0,a2
    800015f0:	b7e9                	j	800015ba <uvmalloc+0x7a>

00000000800015f2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f2:	7179                	addi	sp,sp,-48
    800015f4:	f406                	sd	ra,40(sp)
    800015f6:	f022                	sd	s0,32(sp)
    800015f8:	ec26                	sd	s1,24(sp)
    800015fa:	e84a                	sd	s2,16(sp)
    800015fc:	e44e                	sd	s3,8(sp)
    800015fe:	e052                	sd	s4,0(sp)
    80001600:	1800                	addi	s0,sp,48
    80001602:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001604:	84aa                	mv	s1,a0
    80001606:	6905                	lui	s2,0x1
    80001608:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000160a:	4985                	li	s3,1
    8000160c:	a821                	j	80001624 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000160e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001610:	0532                	slli	a0,a0,0xc
    80001612:	00000097          	auipc	ra,0x0
    80001616:	fe0080e7          	jalr	-32(ra) # 800015f2 <freewalk>
      pagetable[i] = 0;
    8000161a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000161e:	04a1                	addi	s1,s1,8
    80001620:	03248163          	beq	s1,s2,80001642 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001624:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001626:	00f57793          	andi	a5,a0,15
    8000162a:	ff3782e3          	beq	a5,s3,8000160e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000162e:	8905                	andi	a0,a0,1
    80001630:	d57d                	beqz	a0,8000161e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001632:	00007517          	auipc	a0,0x7
    80001636:	b6e50513          	addi	a0,a0,-1170 # 800081a0 <digits+0x160>
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	f04080e7          	jalr	-252(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001642:	8552                	mv	a0,s4
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	3a6080e7          	jalr	934(ra) # 800009ea <kfree>
}
    8000164c:	70a2                	ld	ra,40(sp)
    8000164e:	7402                	ld	s0,32(sp)
    80001650:	64e2                	ld	s1,24(sp)
    80001652:	6942                	ld	s2,16(sp)
    80001654:	69a2                	ld	s3,8(sp)
    80001656:	6a02                	ld	s4,0(sp)
    80001658:	6145                	addi	sp,sp,48
    8000165a:	8082                	ret

000000008000165c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000165c:	1101                	addi	sp,sp,-32
    8000165e:	ec06                	sd	ra,24(sp)
    80001660:	e822                	sd	s0,16(sp)
    80001662:	e426                	sd	s1,8(sp)
    80001664:	1000                	addi	s0,sp,32
    80001666:	84aa                	mv	s1,a0
  if(sz > 0)
    80001668:	e999                	bnez	a1,8000167e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000166a:	8526                	mv	a0,s1
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	f86080e7          	jalr	-122(ra) # 800015f2 <freewalk>
}
    80001674:	60e2                	ld	ra,24(sp)
    80001676:	6442                	ld	s0,16(sp)
    80001678:	64a2                	ld	s1,8(sp)
    8000167a:	6105                	addi	sp,sp,32
    8000167c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000167e:	6605                	lui	a2,0x1
    80001680:	167d                	addi	a2,a2,-1
    80001682:	962e                	add	a2,a2,a1
    80001684:	4685                	li	a3,1
    80001686:	8231                	srli	a2,a2,0xc
    80001688:	4581                	li	a1,0
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	d0a080e7          	jalr	-758(ra) # 80001394 <uvmunmap>
    80001692:	bfe1                	j	8000166a <uvmfree+0xe>

0000000080001694 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001694:	711d                	addi	sp,sp,-96
    80001696:	ec86                	sd	ra,88(sp)
    80001698:	e8a2                	sd	s0,80(sp)
    8000169a:	e4a6                	sd	s1,72(sp)
    8000169c:	e0ca                	sd	s2,64(sp)
    8000169e:	fc4e                	sd	s3,56(sp)
    800016a0:	f852                	sd	s4,48(sp)
    800016a2:	f456                	sd	s5,40(sp)
    800016a4:	f05a                	sd	s6,32(sp)
    800016a6:	ec5e                	sd	s7,24(sp)
    800016a8:	e862                	sd	s8,16(sp)
    800016aa:	e466                	sd	s9,8(sp)
    800016ac:	e06a                	sd	s10,0(sp)
    800016ae:	1080                	addi	s0,sp,96
  pte_t *pte;
  uint64 pa, i;
  uint flags;
//   char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016b0:	ce65                	beqz	a2,800017a8 <uvmcopy+0x114>
    800016b2:	8baa                	mv	s7,a0
    800016b4:	8b2e                	mv	s6,a1
    800016b6:	8ab2                	mv	s5,a2
    800016b8:	4901                	li	s2,0
    flags = PTE_FLAGS(*pte);
    if (flags & PTE_W)
    {
        flags |= PTE_COW;
        flags &= ~PTE_W;
        *pte = PA2PTE(PTE2PA(*pte)) | flags;
    800016ba:	7d7d                	lui	s10,0xfffff
    800016bc:	002d5d13          	srli	s10,s10,0x2
    // memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, PTE2PA(*pte), flags) != 0){
    //   kfree(mem);
      goto err;
    }
    acquire(&lock_for_the_arr_of_ref);
    800016c0:	0000fa17          	auipc	s4,0xf
    800016c4:	4c0a0a13          	addi	s4,s4,1216 # 80010b80 <lock_for_the_arr_of_ref>
    arr_of_ref[(uint64)pa >> PGSHIFT]++;
    800016c8:	5c7d                	li	s8,-1
    800016ca:	00cc5c13          	srli	s8,s8,0xc
    800016ce:	0000fc97          	auipc	s9,0xf
    800016d2:	4eac8c93          	addi	s9,s9,1258 # 80010bb8 <arr_of_ref>
    800016d6:	a895                	j	8000174a <uvmcopy+0xb6>
      panic("uvmcopy: pte should exist");
    800016d8:	00007517          	auipc	a0,0x7
    800016dc:	ad850513          	addi	a0,a0,-1320 # 800081b0 <digits+0x170>
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	e5e080e7          	jalr	-418(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800016e8:	00007517          	auipc	a0,0x7
    800016ec:	ae850513          	addi	a0,a0,-1304 # 800081d0 <digits+0x190>
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	e4e080e7          	jalr	-434(ra) # 8000053e <panic>
        flags &= ~PTE_W;
    800016f8:	3fb77693          	andi	a3,a4,1019
    800016fc:	1006e713          	ori	a4,a3,256
        *pte = PA2PTE(PTE2PA(*pte)) | flags;
    80001700:	01a7f7b3          	and	a5,a5,s10
    80001704:	8fd9                	or	a5,a5,a4
    80001706:	e11c                	sd	a5,0(a0)
    if(mappages(new, i, PGSIZE, PTE2PA(*pte), flags) != 0){
    80001708:	6114                	ld	a3,0(a0)
    8000170a:	82a9                	srli	a3,a3,0xa
    8000170c:	06b2                	slli	a3,a3,0xc
    8000170e:	6605                	lui	a2,0x1
    80001710:	85ca                	mv	a1,s2
    80001712:	855a                	mv	a0,s6
    80001714:	00000097          	auipc	ra,0x0
    80001718:	aba080e7          	jalr	-1350(ra) # 800011ce <mappages>
    8000171c:	89aa                	mv	s3,a0
    8000171e:	ed21                	bnez	a0,80001776 <uvmcopy+0xe2>
    acquire(&lock_for_the_arr_of_ref);
    80001720:	8552                	mv	a0,s4
    80001722:	fffff097          	auipc	ra,0xfffff
    80001726:	5e4080e7          	jalr	1508(ra) # 80000d06 <acquire>
    arr_of_ref[(uint64)pa >> PGSHIFT]++;
    8000172a:	0184f7b3          	and	a5,s1,s8
    8000172e:	078a                	slli	a5,a5,0x2
    80001730:	97e6                	add	a5,a5,s9
    80001732:	4398                	lw	a4,0(a5)
    80001734:	2705                	addiw	a4,a4,1
    80001736:	c398                	sw	a4,0(a5)
    release(&lock_for_the_arr_of_ref);
    80001738:	8552                	mv	a0,s4
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	680080e7          	jalr	1664(ra) # 80000dba <release>
  for(i = 0; i < sz; i += PGSIZE){
    80001742:	6785                	lui	a5,0x1
    80001744:	993e                	add	s2,s2,a5
    80001746:	05597263          	bgeu	s2,s5,8000178a <uvmcopy+0xf6>
    if((pte = walk(old, i, 0)) == 0)
    8000174a:	4601                	li	a2,0
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855e                	mv	a0,s7
    80001750:	00000097          	auipc	ra,0x0
    80001754:	996080e7          	jalr	-1642(ra) # 800010e6 <walk>
    80001758:	d141                	beqz	a0,800016d8 <uvmcopy+0x44>
    if((*pte & PTE_V) == 0)
    8000175a:	611c                	ld	a5,0(a0)
    8000175c:	0017f713          	andi	a4,a5,1
    80001760:	d741                	beqz	a4,800016e8 <uvmcopy+0x54>
    pa = PTE2PA(*pte);
    80001762:	00a7d493          	srli	s1,a5,0xa
    flags = PTE_FLAGS(*pte);
    80001766:	0007871b          	sext.w	a4,a5
    if (flags & PTE_W)
    8000176a:	0047f693          	andi	a3,a5,4
    8000176e:	f6c9                	bnez	a3,800016f8 <uvmcopy+0x64>
    flags = PTE_FLAGS(*pte);
    80001770:	3ff77713          	andi	a4,a4,1023
    80001774:	bf51                	j	80001708 <uvmcopy+0x74>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001776:	4685                	li	a3,1
    80001778:	00c95613          	srli	a2,s2,0xc
    8000177c:	4581                	li	a1,0
    8000177e:	855a                	mv	a0,s6
    80001780:	00000097          	auipc	ra,0x0
    80001784:	c14080e7          	jalr	-1004(ra) # 80001394 <uvmunmap>
  return -1;
    80001788:	59fd                	li	s3,-1
}
    8000178a:	854e                	mv	a0,s3
    8000178c:	60e6                	ld	ra,88(sp)
    8000178e:	6446                	ld	s0,80(sp)
    80001790:	64a6                	ld	s1,72(sp)
    80001792:	6906                	ld	s2,64(sp)
    80001794:	79e2                	ld	s3,56(sp)
    80001796:	7a42                	ld	s4,48(sp)
    80001798:	7aa2                	ld	s5,40(sp)
    8000179a:	7b02                	ld	s6,32(sp)
    8000179c:	6be2                	ld	s7,24(sp)
    8000179e:	6c42                	ld	s8,16(sp)
    800017a0:	6ca2                	ld	s9,8(sp)
    800017a2:	6d02                	ld	s10,0(sp)
    800017a4:	6125                	addi	sp,sp,96
    800017a6:	8082                	ret
  return 0;
    800017a8:	4981                	li	s3,0
    800017aa:	b7c5                	j	8000178a <uvmcopy+0xf6>

00000000800017ac <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017ac:	1141                	addi	sp,sp,-16
    800017ae:	e406                	sd	ra,8(sp)
    800017b0:	e022                	sd	s0,0(sp)
    800017b2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017b4:	4601                	li	a2,0
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	930080e7          	jalr	-1744(ra) # 800010e6 <walk>
  if(pte == 0)
    800017be:	c901                	beqz	a0,800017ce <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017c0:	611c                	ld	a5,0(a0)
    800017c2:	9bbd                	andi	a5,a5,-17
    800017c4:	e11c                	sd	a5,0(a0)
}
    800017c6:	60a2                	ld	ra,8(sp)
    800017c8:	6402                	ld	s0,0(sp)
    800017ca:	0141                	addi	sp,sp,16
    800017cc:	8082                	ret
    panic("uvmclear");
    800017ce:	00007517          	auipc	a0,0x7
    800017d2:	a2250513          	addi	a0,a0,-1502 # 800081f0 <digits+0x1b0>
    800017d6:	fffff097          	auipc	ra,0xfffff
    800017da:	d68080e7          	jalr	-664(ra) # 8000053e <panic>

00000000800017de <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017de:	cef1                	beqz	a3,800018ba <copyout+0xdc>
{
    800017e0:	711d                	addi	sp,sp,-96
    800017e2:	ec86                	sd	ra,88(sp)
    800017e4:	e8a2                	sd	s0,80(sp)
    800017e6:	e4a6                	sd	s1,72(sp)
    800017e8:	e0ca                	sd	s2,64(sp)
    800017ea:	fc4e                	sd	s3,56(sp)
    800017ec:	f852                	sd	s4,48(sp)
    800017ee:	f456                	sd	s5,40(sp)
    800017f0:	f05a                	sd	s6,32(sp)
    800017f2:	ec5e                	sd	s7,24(sp)
    800017f4:	e862                	sd	s8,16(sp)
    800017f6:	e466                	sd	s9,8(sp)
    800017f8:	e06a                	sd	s10,0(sp)
    800017fa:	1080                	addi	s0,sp,96
    800017fc:	8c2a                	mv	s8,a0
    800017fe:	8b2e                	mv	s6,a1
    80001800:	8bb2                	mv	s7,a2
    80001802:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001804:	74fd                	lui	s1,0xfffff
    80001806:	8ced                	and	s1,s1,a1
    if (va0 >= MAXVA)
    80001808:	57fd                	li	a5,-1
    8000180a:	83e9                	srli	a5,a5,0x1a
    8000180c:	0a97e963          	bltu	a5,s1,800018be <copyout+0xe0>
    80001810:	8cbe                	mv	s9,a5
    80001812:	a81d                	j	80001848 <copyout+0x6a>
        mappages(pagetable, (uint64)PGROUNDDOWN(va0), PGSIZE, (uint64)mem, flags);

        // pa0 = walkaddr(pagetable, va0);
        pa0 = (uint64)mem;
    }
    n = PGSIZE - (dstva - va0);
    80001814:	6905                	lui	s2,0x1
    80001816:	9926                	add	s2,s2,s1
    80001818:	41690a33          	sub	s4,s2,s6
    if(n > len)
    8000181c:	014af363          	bgeu	s5,s4,80001822 <copyout+0x44>
    80001820:	8a56                	mv	s4,s5
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001822:	409b0533          	sub	a0,s6,s1
    80001826:	000a061b          	sext.w	a2,s4
    8000182a:	85de                	mv	a1,s7
    8000182c:	954e                	add	a0,a0,s3
    8000182e:	fffff097          	auipc	ra,0xfffff
    80001832:	630080e7          	jalr	1584(ra) # 80000e5e <memmove>

    len -= n;
    80001836:	414a8ab3          	sub	s5,s5,s4
    src += n;
    8000183a:	9bd2                	add	s7,s7,s4
  while(len > 0){
    8000183c:	060a8d63          	beqz	s5,800018b6 <copyout+0xd8>
    if (va0 >= MAXVA)
    80001840:	092ce163          	bltu	s9,s2,800018c2 <copyout+0xe4>
    va0 = PGROUNDDOWN(dstva);
    80001844:	84ca                	mv	s1,s2
    dstva = va0 + PGSIZE;
    80001846:	8b4a                	mv	s6,s2
    pa0 = walkaddr(pagetable, va0);
    80001848:	85a6                	mv	a1,s1
    8000184a:	8562                	mv	a0,s8
    8000184c:	00000097          	auipc	ra,0x0
    80001850:	940080e7          	jalr	-1728(ra) # 8000118c <walkaddr>
    80001854:	89aa                	mv	s3,a0
    if(pa0 == 0)
    80001856:	c925                	beqz	a0,800018c6 <copyout+0xe8>
    pte_t *pte = walk(pagetable, va0, 0);
    80001858:	4601                	li	a2,0
    8000185a:	85a6                	mv	a1,s1
    8000185c:	8562                	mv	a0,s8
    8000185e:	00000097          	auipc	ra,0x0
    80001862:	888080e7          	jalr	-1912(ra) # 800010e6 <walk>
    80001866:	892a                	mv	s2,a0
    if (pte == 0)
    80001868:	cd35                	beqz	a0,800018e4 <copyout+0x106>
    flags = PTE_FLAGS(*pte);
    8000186a:	00052d03          	lw	s10,0(a0)
    if (flags & PTE_COW)
    8000186e:	100d7793          	andi	a5,s10,256
    80001872:	d3cd                	beqz	a5,80001814 <copyout+0x36>
        char *mem = (char *)kalloc();
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	364080e7          	jalr	868(ra) # 80000bd8 <kalloc>
    8000187c:	8a2a                	mv	s4,a0
        *pte = 0;
    8000187e:	00093023          	sd	zero,0(s2) # 1000 <_entry-0x7ffff000>
        if (mem == 0)
    80001882:	c13d                	beqz	a0,800018e8 <copyout+0x10a>
        flags = flags & (~PTE_COW);
    80001884:	2ffd7d13          	andi	s10,s10,767
        memmove(mem, (char *)pa0, PGSIZE);
    80001888:	6605                	lui	a2,0x1
    8000188a:	85ce                	mv	a1,s3
    8000188c:	fffff097          	auipc	ra,0xfffff
    80001890:	5d2080e7          	jalr	1490(ra) # 80000e5e <memmove>
        kfree((char *)pa0);
    80001894:	854e                	mv	a0,s3
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	154080e7          	jalr	340(ra) # 800009ea <kfree>
        mappages(pagetable, (uint64)PGROUNDDOWN(va0), PGSIZE, (uint64)mem, flags);
    8000189e:	89d2                	mv	s3,s4
    800018a0:	004d6713          	ori	a4,s10,4
    800018a4:	86d2                	mv	a3,s4
    800018a6:	6605                	lui	a2,0x1
    800018a8:	85a6                	mv	a1,s1
    800018aa:	8562                	mv	a0,s8
    800018ac:	00000097          	auipc	ra,0x0
    800018b0:	922080e7          	jalr	-1758(ra) # 800011ce <mappages>
        pa0 = (uint64)mem;
    800018b4:	b785                	j	80001814 <copyout+0x36>
  }
  return 0;
    800018b6:	4501                	li	a0,0
    800018b8:	a801                	j	800018c8 <copyout+0xea>
    800018ba:	4501                	li	a0,0
}
    800018bc:	8082                	ret
        return -1;
    800018be:	557d                	li	a0,-1
    800018c0:	a021                	j	800018c8 <copyout+0xea>
    800018c2:	557d                	li	a0,-1
    800018c4:	a011                	j	800018c8 <copyout+0xea>
      return -1;
    800018c6:	557d                	li	a0,-1
}
    800018c8:	60e6                	ld	ra,88(sp)
    800018ca:	6446                	ld	s0,80(sp)
    800018cc:	64a6                	ld	s1,72(sp)
    800018ce:	6906                	ld	s2,64(sp)
    800018d0:	79e2                	ld	s3,56(sp)
    800018d2:	7a42                	ld	s4,48(sp)
    800018d4:	7aa2                	ld	s5,40(sp)
    800018d6:	7b02                	ld	s6,32(sp)
    800018d8:	6be2                	ld	s7,24(sp)
    800018da:	6c42                	ld	s8,16(sp)
    800018dc:	6ca2                	ld	s9,8(sp)
    800018de:	6d02                	ld	s10,0(sp)
    800018e0:	6125                	addi	sp,sp,96
    800018e2:	8082                	ret
        return -1;
    800018e4:	557d                	li	a0,-1
    800018e6:	b7cd                	j	800018c8 <copyout+0xea>
            return -1;
    800018e8:	557d                	li	a0,-1
    800018ea:	bff9                	j	800018c8 <copyout+0xea>

00000000800018ec <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018ec:	caa5                	beqz	a3,8000195c <copyin+0x70>
{
    800018ee:	715d                	addi	sp,sp,-80
    800018f0:	e486                	sd	ra,72(sp)
    800018f2:	e0a2                	sd	s0,64(sp)
    800018f4:	fc26                	sd	s1,56(sp)
    800018f6:	f84a                	sd	s2,48(sp)
    800018f8:	f44e                	sd	s3,40(sp)
    800018fa:	f052                	sd	s4,32(sp)
    800018fc:	ec56                	sd	s5,24(sp)
    800018fe:	e85a                	sd	s6,16(sp)
    80001900:	e45e                	sd	s7,8(sp)
    80001902:	e062                	sd	s8,0(sp)
    80001904:	0880                	addi	s0,sp,80
    80001906:	8b2a                	mv	s6,a0
    80001908:	8a2e                	mv	s4,a1
    8000190a:	8c32                	mv	s8,a2
    8000190c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000190e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001910:	6a85                	lui	s5,0x1
    80001912:	a01d                	j	80001938 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001914:	018505b3          	add	a1,a0,s8
    80001918:	0004861b          	sext.w	a2,s1
    8000191c:	412585b3          	sub	a1,a1,s2
    80001920:	8552                	mv	a0,s4
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	53c080e7          	jalr	1340(ra) # 80000e5e <memmove>

    len -= n;
    8000192a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000192e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001930:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001934:	02098263          	beqz	s3,80001958 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001938:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000193c:	85ca                	mv	a1,s2
    8000193e:	855a                	mv	a0,s6
    80001940:	00000097          	auipc	ra,0x0
    80001944:	84c080e7          	jalr	-1972(ra) # 8000118c <walkaddr>
    if(pa0 == 0)
    80001948:	cd01                	beqz	a0,80001960 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000194a:	418904b3          	sub	s1,s2,s8
    8000194e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001950:	fc99f2e3          	bgeu	s3,s1,80001914 <copyin+0x28>
    80001954:	84ce                	mv	s1,s3
    80001956:	bf7d                	j	80001914 <copyin+0x28>
  }
  return 0;
    80001958:	4501                	li	a0,0
    8000195a:	a021                	j	80001962 <copyin+0x76>
    8000195c:	4501                	li	a0,0
}
    8000195e:	8082                	ret
      return -1;
    80001960:	557d                	li	a0,-1
}
    80001962:	60a6                	ld	ra,72(sp)
    80001964:	6406                	ld	s0,64(sp)
    80001966:	74e2                	ld	s1,56(sp)
    80001968:	7942                	ld	s2,48(sp)
    8000196a:	79a2                	ld	s3,40(sp)
    8000196c:	7a02                	ld	s4,32(sp)
    8000196e:	6ae2                	ld	s5,24(sp)
    80001970:	6b42                	ld	s6,16(sp)
    80001972:	6ba2                	ld	s7,8(sp)
    80001974:	6c02                	ld	s8,0(sp)
    80001976:	6161                	addi	sp,sp,80
    80001978:	8082                	ret

000000008000197a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000197a:	c6c5                	beqz	a3,80001a22 <copyinstr+0xa8>
{
    8000197c:	715d                	addi	sp,sp,-80
    8000197e:	e486                	sd	ra,72(sp)
    80001980:	e0a2                	sd	s0,64(sp)
    80001982:	fc26                	sd	s1,56(sp)
    80001984:	f84a                	sd	s2,48(sp)
    80001986:	f44e                	sd	s3,40(sp)
    80001988:	f052                	sd	s4,32(sp)
    8000198a:	ec56                	sd	s5,24(sp)
    8000198c:	e85a                	sd	s6,16(sp)
    8000198e:	e45e                	sd	s7,8(sp)
    80001990:	0880                	addi	s0,sp,80
    80001992:	8a2a                	mv	s4,a0
    80001994:	8b2e                	mv	s6,a1
    80001996:	8bb2                	mv	s7,a2
    80001998:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000199a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000199c:	6985                	lui	s3,0x1
    8000199e:	a035                	j	800019ca <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019a0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019a4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019a6:	0017b793          	seqz	a5,a5
    800019aa:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019ae:	60a6                	ld	ra,72(sp)
    800019b0:	6406                	ld	s0,64(sp)
    800019b2:	74e2                	ld	s1,56(sp)
    800019b4:	7942                	ld	s2,48(sp)
    800019b6:	79a2                	ld	s3,40(sp)
    800019b8:	7a02                	ld	s4,32(sp)
    800019ba:	6ae2                	ld	s5,24(sp)
    800019bc:	6b42                	ld	s6,16(sp)
    800019be:	6ba2                	ld	s7,8(sp)
    800019c0:	6161                	addi	sp,sp,80
    800019c2:	8082                	ret
    srcva = va0 + PGSIZE;
    800019c4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019c8:	c8a9                	beqz	s1,80001a1a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800019ca:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019ce:	85ca                	mv	a1,s2
    800019d0:	8552                	mv	a0,s4
    800019d2:	fffff097          	auipc	ra,0xfffff
    800019d6:	7ba080e7          	jalr	1978(ra) # 8000118c <walkaddr>
    if(pa0 == 0)
    800019da:	c131                	beqz	a0,80001a1e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800019dc:	41790833          	sub	a6,s2,s7
    800019e0:	984e                	add	a6,a6,s3
    if(n > max)
    800019e2:	0104f363          	bgeu	s1,a6,800019e8 <copyinstr+0x6e>
    800019e6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800019e8:	955e                	add	a0,a0,s7
    800019ea:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800019ee:	fc080be3          	beqz	a6,800019c4 <copyinstr+0x4a>
    800019f2:	985a                	add	a6,a6,s6
    800019f4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800019f6:	41650633          	sub	a2,a0,s6
    800019fa:	14fd                	addi	s1,s1,-1
    800019fc:	9b26                	add	s6,s6,s1
    800019fe:	00f60733          	add	a4,a2,a5
    80001a02:	00074703          	lbu	a4,0(a4)
    80001a06:	df49                	beqz	a4,800019a0 <copyinstr+0x26>
        *dst = *p;
    80001a08:	00e78023          	sb	a4,0(a5)
      --max;
    80001a0c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a10:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a12:	ff0796e3          	bne	a5,a6,800019fe <copyinstr+0x84>
      dst++;
    80001a16:	8b42                	mv	s6,a6
    80001a18:	b775                	j	800019c4 <copyinstr+0x4a>
    80001a1a:	4781                	li	a5,0
    80001a1c:	b769                	j	800019a6 <copyinstr+0x2c>
      return -1;
    80001a1e:	557d                	li	a0,-1
    80001a20:	b779                	j	800019ae <copyinstr+0x34>
  int got_null = 0;
    80001a22:	4781                	li	a5,0
  if(got_null){
    80001a24:	0017b793          	seqz	a5,a5
    80001a28:	40f00533          	neg	a0,a5
}
    80001a2c:	8082                	ret

0000000080001a2e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001a2e:	7139                	addi	sp,sp,-64
    80001a30:	fc06                	sd	ra,56(sp)
    80001a32:	f822                	sd	s0,48(sp)
    80001a34:	f426                	sd	s1,40(sp)
    80001a36:	f04a                	sd	s2,32(sp)
    80001a38:	ec4e                	sd	s3,24(sp)
    80001a3a:	e852                	sd	s4,16(sp)
    80001a3c:	e456                	sd	s5,8(sp)
    80001a3e:	e05a                	sd	s6,0(sp)
    80001a40:	0080                	addi	s0,sp,64
    80001a42:	89aa                	mv	s3,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80001a44:	0022f497          	auipc	s1,0x22f
    80001a48:	5a448493          	addi	s1,s1,1444 # 80230fe8 <proc>
    {
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int)(p - proc));
    80001a4c:	8b26                	mv	s6,s1
    80001a4e:	00006a97          	auipc	s5,0x6
    80001a52:	5b2a8a93          	addi	s5,s5,1458 # 80008000 <etext>
    80001a56:	04000937          	lui	s2,0x4000
    80001a5a:	197d                	addi	s2,s2,-1
    80001a5c:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001a5e:	00236a17          	auipc	s4,0x236
    80001a62:	98aa0a13          	addi	s4,s4,-1654 # 802373e8 <tickslock>
        char *pa = kalloc();
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	172080e7          	jalr	370(ra) # 80000bd8 <kalloc>
    80001a6e:	862a                	mv	a2,a0
        if (pa == 0)
    80001a70:	c131                	beqz	a0,80001ab4 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001a72:	416485b3          	sub	a1,s1,s6
    80001a76:	8591                	srai	a1,a1,0x4
    80001a78:	000ab783          	ld	a5,0(s5)
    80001a7c:	02f585b3          	mul	a1,a1,a5
    80001a80:	2585                	addiw	a1,a1,1
    80001a82:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a86:	4719                	li	a4,6
    80001a88:	6685                	lui	a3,0x1
    80001a8a:	40b905b3          	sub	a1,s2,a1
    80001a8e:	854e                	mv	a0,s3
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	7de080e7          	jalr	2014(ra) # 8000126e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001a98:	19048493          	addi	s1,s1,400
    80001a9c:	fd4495e3          	bne	s1,s4,80001a66 <proc_mapstacks+0x38>
    }
}
    80001aa0:	70e2                	ld	ra,56(sp)
    80001aa2:	7442                	ld	s0,48(sp)
    80001aa4:	74a2                	ld	s1,40(sp)
    80001aa6:	7902                	ld	s2,32(sp)
    80001aa8:	69e2                	ld	s3,24(sp)
    80001aaa:	6a42                	ld	s4,16(sp)
    80001aac:	6aa2                	ld	s5,8(sp)
    80001aae:	6b02                	ld	s6,0(sp)
    80001ab0:	6121                	addi	sp,sp,64
    80001ab2:	8082                	ret
            panic("kalloc");
    80001ab4:	00006517          	auipc	a0,0x6
    80001ab8:	74c50513          	addi	a0,a0,1868 # 80008200 <digits+0x1c0>
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	a82080e7          	jalr	-1406(ra) # 8000053e <panic>

0000000080001ac4 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001ac4:	7139                	addi	sp,sp,-64
    80001ac6:	fc06                	sd	ra,56(sp)
    80001ac8:	f822                	sd	s0,48(sp)
    80001aca:	f426                	sd	s1,40(sp)
    80001acc:	f04a                	sd	s2,32(sp)
    80001ace:	ec4e                	sd	s3,24(sp)
    80001ad0:	e852                	sd	s4,16(sp)
    80001ad2:	e456                	sd	s5,8(sp)
    80001ad4:	e05a                	sd	s6,0(sp)
    80001ad6:	0080                	addi	s0,sp,64
    struct proc *p;

    initlock(&pid_lock, "nextpid");
    80001ad8:	00006597          	auipc	a1,0x6
    80001adc:	73058593          	addi	a1,a1,1840 # 80008208 <digits+0x1c8>
    80001ae0:	0022f517          	auipc	a0,0x22f
    80001ae4:	0d850513          	addi	a0,a0,216 # 80230bb8 <pid_lock>
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	18e080e7          	jalr	398(ra) # 80000c76 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001af0:	00006597          	auipc	a1,0x6
    80001af4:	72058593          	addi	a1,a1,1824 # 80008210 <digits+0x1d0>
    80001af8:	0022f517          	auipc	a0,0x22f
    80001afc:	0d850513          	addi	a0,a0,216 # 80230bd0 <wait_lock>
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	176080e7          	jalr	374(ra) # 80000c76 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b08:	0022f497          	auipc	s1,0x22f
    80001b0c:	4e048493          	addi	s1,s1,1248 # 80230fe8 <proc>
    {
        initlock(&p->lock, "proc");
    80001b10:	00006b17          	auipc	s6,0x6
    80001b14:	710b0b13          	addi	s6,s6,1808 # 80008220 <digits+0x1e0>
        p->state = UNUSED;
        p->kstack = KSTACK((int)(p - proc));
    80001b18:	8aa6                	mv	s5,s1
    80001b1a:	00006a17          	auipc	s4,0x6
    80001b1e:	4e6a0a13          	addi	s4,s4,1254 # 80008000 <etext>
    80001b22:	04000937          	lui	s2,0x4000
    80001b26:	197d                	addi	s2,s2,-1
    80001b28:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b2a:	00236997          	auipc	s3,0x236
    80001b2e:	8be98993          	addi	s3,s3,-1858 # 802373e8 <tickslock>
        initlock(&p->lock, "proc");
    80001b32:	85da                	mv	a1,s6
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	140080e7          	jalr	320(ra) # 80000c76 <initlock>
        p->state = UNUSED;
    80001b3e:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001b42:	415487b3          	sub	a5,s1,s5
    80001b46:	8791                	srai	a5,a5,0x4
    80001b48:	000a3703          	ld	a4,0(s4)
    80001b4c:	02e787b3          	mul	a5,a5,a4
    80001b50:	2785                	addiw	a5,a5,1
    80001b52:	00d7979b          	slliw	a5,a5,0xd
    80001b56:	40f907b3          	sub	a5,s2,a5
    80001b5a:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001b5c:	19048493          	addi	s1,s1,400
    80001b60:	fd3499e3          	bne	s1,s3,80001b32 <procinit+0x6e>
    }
}
    80001b64:	70e2                	ld	ra,56(sp)
    80001b66:	7442                	ld	s0,48(sp)
    80001b68:	74a2                	ld	s1,40(sp)
    80001b6a:	7902                	ld	s2,32(sp)
    80001b6c:	69e2                	ld	s3,24(sp)
    80001b6e:	6a42                	ld	s4,16(sp)
    80001b70:	6aa2                	ld	s5,8(sp)
    80001b72:	6b02                	ld	s6,0(sp)
    80001b74:	6121                	addi	sp,sp,64
    80001b76:	8082                	ret

0000000080001b78 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001b78:	1141                	addi	sp,sp,-16
    80001b7a:	e422                	sd	s0,8(sp)
    80001b7c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b7e:	8512                	mv	a0,tp
    int id = r_tp();
    return id;
}
    80001b80:	2501                	sext.w	a0,a0
    80001b82:	6422                	ld	s0,8(sp)
    80001b84:	0141                	addi	sp,sp,16
    80001b86:	8082                	ret

0000000080001b88 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
    80001b8e:	8792                	mv	a5,tp
    int id = cpuid();
    struct cpu *c = &cpus[id];
    80001b90:	2781                	sext.w	a5,a5
    80001b92:	079e                	slli	a5,a5,0x7
    return c;
}
    80001b94:	0022f517          	auipc	a0,0x22f
    80001b98:	05450513          	addi	a0,a0,84 # 80230be8 <cpus>
    80001b9c:	953e                	add	a0,a0,a5
    80001b9e:	6422                	ld	s0,8(sp)
    80001ba0:	0141                	addi	sp,sp,16
    80001ba2:	8082                	ret

0000000080001ba4 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	1000                	addi	s0,sp,32
    push_off();
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	10c080e7          	jalr	268(ra) # 80000cba <push_off>
    80001bb6:	8792                	mv	a5,tp
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    80001bb8:	2781                	sext.w	a5,a5
    80001bba:	079e                	slli	a5,a5,0x7
    80001bbc:	0022f717          	auipc	a4,0x22f
    80001bc0:	ffc70713          	addi	a4,a4,-4 # 80230bb8 <pid_lock>
    80001bc4:	97ba                	add	a5,a5,a4
    80001bc6:	7b84                	ld	s1,48(a5)
    pop_off();
    80001bc8:	fffff097          	auipc	ra,0xfffff
    80001bcc:	192080e7          	jalr	402(ra) # 80000d5a <pop_off>
    return p;
}
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	60e2                	ld	ra,24(sp)
    80001bd4:	6442                	ld	s0,16(sp)
    80001bd6:	64a2                	ld	s1,8(sp)
    80001bd8:	6105                	addi	sp,sp,32
    80001bda:	8082                	ret

0000000080001bdc <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001bdc:	1141                	addi	sp,sp,-16
    80001bde:	e406                	sd	ra,8(sp)
    80001be0:	e022                	sd	s0,0(sp)
    80001be2:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001be4:	00000097          	auipc	ra,0x0
    80001be8:	fc0080e7          	jalr	-64(ra) # 80001ba4 <myproc>
    80001bec:	fffff097          	auipc	ra,0xfffff
    80001bf0:	1ce080e7          	jalr	462(ra) # 80000dba <release>

    if (first)
    80001bf4:	00007797          	auipc	a5,0x7
    80001bf8:	cbc7a783          	lw	a5,-836(a5) # 800088b0 <first.1>
    80001bfc:	eb89                	bnez	a5,80001c0e <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001bfe:	00001097          	auipc	ra,0x1
    80001c02:	0f2080e7          	jalr	242(ra) # 80002cf0 <usertrapret>
}
    80001c06:	60a2                	ld	ra,8(sp)
    80001c08:	6402                	ld	s0,0(sp)
    80001c0a:	0141                	addi	sp,sp,16
    80001c0c:	8082                	ret
        first = 0;
    80001c0e:	00007797          	auipc	a5,0x7
    80001c12:	ca07a123          	sw	zero,-862(a5) # 800088b0 <first.1>
        fsinit(ROOTDEV);
    80001c16:	4505                	li	a0,1
    80001c18:	00002097          	auipc	ra,0x2
    80001c1c:	050080e7          	jalr	80(ra) # 80003c68 <fsinit>
    80001c20:	bff9                	j	80001bfe <forkret+0x22>

0000000080001c22 <allocpid>:
{
    80001c22:	1101                	addi	sp,sp,-32
    80001c24:	ec06                	sd	ra,24(sp)
    80001c26:	e822                	sd	s0,16(sp)
    80001c28:	e426                	sd	s1,8(sp)
    80001c2a:	e04a                	sd	s2,0(sp)
    80001c2c:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001c2e:	0022f917          	auipc	s2,0x22f
    80001c32:	f8a90913          	addi	s2,s2,-118 # 80230bb8 <pid_lock>
    80001c36:	854a                	mv	a0,s2
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	0ce080e7          	jalr	206(ra) # 80000d06 <acquire>
    pid = nextpid;
    80001c40:	00007797          	auipc	a5,0x7
    80001c44:	c7478793          	addi	a5,a5,-908 # 800088b4 <nextpid>
    80001c48:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001c4a:	0014871b          	addiw	a4,s1,1
    80001c4e:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001c50:	854a                	mv	a0,s2
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	168080e7          	jalr	360(ra) # 80000dba <release>
}
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	60e2                	ld	ra,24(sp)
    80001c5e:	6442                	ld	s0,16(sp)
    80001c60:	64a2                	ld	s1,8(sp)
    80001c62:	6902                	ld	s2,0(sp)
    80001c64:	6105                	addi	sp,sp,32
    80001c66:	8082                	ret

0000000080001c68 <proc_pagetable>:
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	e04a                	sd	s2,0(sp)
    80001c72:	1000                	addi	s0,sp,32
    80001c74:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	7e2080e7          	jalr	2018(ra) # 80001458 <uvmcreate>
    80001c7e:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001c80:	c121                	beqz	a0,80001cc0 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c82:	4729                	li	a4,10
    80001c84:	00005697          	auipc	a3,0x5
    80001c88:	37c68693          	addi	a3,a3,892 # 80007000 <_trampoline>
    80001c8c:	6605                	lui	a2,0x1
    80001c8e:	040005b7          	lui	a1,0x4000
    80001c92:	15fd                	addi	a1,a1,-1
    80001c94:	05b2                	slli	a1,a1,0xc
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	538080e7          	jalr	1336(ra) # 800011ce <mappages>
    80001c9e:	02054863          	bltz	a0,80001cce <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ca2:	4719                	li	a4,6
    80001ca4:	05893683          	ld	a3,88(s2)
    80001ca8:	6605                	lui	a2,0x1
    80001caa:	020005b7          	lui	a1,0x2000
    80001cae:	15fd                	addi	a1,a1,-1
    80001cb0:	05b6                	slli	a1,a1,0xd
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	51a080e7          	jalr	1306(ra) # 800011ce <mappages>
    80001cbc:	02054163          	bltz	a0,80001cde <proc_pagetable+0x76>
}
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	60e2                	ld	ra,24(sp)
    80001cc4:	6442                	ld	s0,16(sp)
    80001cc6:	64a2                	ld	s1,8(sp)
    80001cc8:	6902                	ld	s2,0(sp)
    80001cca:	6105                	addi	sp,sp,32
    80001ccc:	8082                	ret
        uvmfree(pagetable, 0);
    80001cce:	4581                	li	a1,0
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	98a080e7          	jalr	-1654(ra) # 8000165c <uvmfree>
        return 0;
    80001cda:	4481                	li	s1,0
    80001cdc:	b7d5                	j	80001cc0 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cde:	4681                	li	a3,0
    80001ce0:	4605                	li	a2,1
    80001ce2:	040005b7          	lui	a1,0x4000
    80001ce6:	15fd                	addi	a1,a1,-1
    80001ce8:	05b2                	slli	a1,a1,0xc
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	6a8080e7          	jalr	1704(ra) # 80001394 <uvmunmap>
        uvmfree(pagetable, 0);
    80001cf4:	4581                	li	a1,0
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	964080e7          	jalr	-1692(ra) # 8000165c <uvmfree>
        return 0;
    80001d00:	4481                	li	s1,0
    80001d02:	bf7d                	j	80001cc0 <proc_pagetable+0x58>

0000000080001d04 <proc_freepagetable>:
{
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	e04a                	sd	s2,0(sp)
    80001d0e:	1000                	addi	s0,sp,32
    80001d10:	84aa                	mv	s1,a0
    80001d12:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d14:	4681                	li	a3,0
    80001d16:	4605                	li	a2,1
    80001d18:	040005b7          	lui	a1,0x4000
    80001d1c:	15fd                	addi	a1,a1,-1
    80001d1e:	05b2                	slli	a1,a1,0xc
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	674080e7          	jalr	1652(ra) # 80001394 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d28:	4681                	li	a3,0
    80001d2a:	4605                	li	a2,1
    80001d2c:	020005b7          	lui	a1,0x2000
    80001d30:	15fd                	addi	a1,a1,-1
    80001d32:	05b6                	slli	a1,a1,0xd
    80001d34:	8526                	mv	a0,s1
    80001d36:	fffff097          	auipc	ra,0xfffff
    80001d3a:	65e080e7          	jalr	1630(ra) # 80001394 <uvmunmap>
    uvmfree(pagetable, sz);
    80001d3e:	85ca                	mv	a1,s2
    80001d40:	8526                	mv	a0,s1
    80001d42:	00000097          	auipc	ra,0x0
    80001d46:	91a080e7          	jalr	-1766(ra) # 8000165c <uvmfree>
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6902                	ld	s2,0(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret

0000000080001d56 <freeproc>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	1000                	addi	s0,sp,32
    80001d60:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001d62:	6d28                	ld	a0,88(a0)
    80001d64:	c509                	beqz	a0,80001d6e <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	c84080e7          	jalr	-892(ra) # 800009ea <kfree>
    p->trapframe = 0;
    80001d6e:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001d72:	68a8                	ld	a0,80(s1)
    80001d74:	c511                	beqz	a0,80001d80 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001d76:	64ac                	ld	a1,72(s1)
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	f8c080e7          	jalr	-116(ra) # 80001d04 <proc_freepagetable>
    p->pagetable = 0;
    80001d80:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001d84:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001d88:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001d8c:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001d90:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001d94:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001d98:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001d9c:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001da0:	0004ac23          	sw	zero,24(s1)
}
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret

0000000080001dae <allocproc>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	e04a                	sd	s2,0(sp)
    80001db8:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001dba:	0022f497          	auipc	s1,0x22f
    80001dbe:	22e48493          	addi	s1,s1,558 # 80230fe8 <proc>
    80001dc2:	00235917          	auipc	s2,0x235
    80001dc6:	62690913          	addi	s2,s2,1574 # 802373e8 <tickslock>
        acquire(&p->lock);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	f3a080e7          	jalr	-198(ra) # 80000d06 <acquire>
        if (p->state == UNUSED)
    80001dd4:	4c9c                	lw	a5,24(s1)
    80001dd6:	cf81                	beqz	a5,80001dee <allocproc+0x40>
            release(&p->lock);
    80001dd8:	8526                	mv	a0,s1
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	fe0080e7          	jalr	-32(ra) # 80000dba <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001de2:	19048493          	addi	s1,s1,400
    80001de6:	ff2492e3          	bne	s1,s2,80001dca <allocproc+0x1c>
    return 0;
    80001dea:	4481                	li	s1,0
    80001dec:	a071                	j	80001e78 <allocproc+0xca>
    p->pid = allocpid();
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	e34080e7          	jalr	-460(ra) # 80001c22 <allocpid>
    80001df6:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001df8:	4785                	li	a5,1
    80001dfa:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	ddc080e7          	jalr	-548(ra) # 80000bd8 <kalloc>
    80001e04:	892a                	mv	s2,a0
    80001e06:	eca8                	sd	a0,88(s1)
    80001e08:	cd3d                	beqz	a0,80001e86 <allocproc+0xd8>
    p->pagetable = proc_pagetable(p);
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	00000097          	auipc	ra,0x0
    80001e10:	e5c080e7          	jalr	-420(ra) # 80001c68 <proc_pagetable>
    80001e14:	892a                	mv	s2,a0
    80001e16:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001e18:	c159                	beqz	a0,80001e9e <allocproc+0xf0>
    memset(&p->context, 0, sizeof(p->context));
    80001e1a:	07000613          	li	a2,112
    80001e1e:	4581                	li	a1,0
    80001e20:	06048513          	addi	a0,s1,96
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	fde080e7          	jalr	-34(ra) # 80000e02 <memset>
    p->context.ra = (uint64)forkret;
    80001e2c:	00000797          	auipc	a5,0x0
    80001e30:	db078793          	addi	a5,a5,-592 # 80001bdc <forkret>
    80001e34:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001e36:	60bc                	ld	a5,64(s1)
    80001e38:	6705                	lui	a4,0x1
    80001e3a:	97ba                	add	a5,a5,a4
    80001e3c:	f4bc                	sd	a5,104(s1)
    p->rtime = 0;
    80001e3e:	1604a423          	sw	zero,360(s1)
    p->etime = 0;
    80001e42:	1604aa23          	sw	zero,372(s1)
    p->ctime = ticks;
    80001e46:	00007797          	auipc	a5,0x7
    80001e4a:	aea7a783          	lw	a5,-1302(a5) # 80008930 <ticks>
    80001e4e:	16f4a823          	sw	a5,368(s1)
    p->my_rtime = 0;
    80001e52:	1604a623          	sw	zero,364(s1)
    p->stime = 0;
    80001e56:	1804a023          	sw	zero,384(s1)
    p->wtime = 0;
    80001e5a:	1804a223          	sw	zero,388(s1)
    p->num_sched = 0;
    80001e5e:	1804a623          	sw	zero,396(s1)
    p->rbi = -1;
    80001e62:	57fd                	li	a5,-1
    80001e64:	18f4a423          	sw	a5,392(s1)
    p->static_priority = 50;
    80001e68:	03200793          	li	a5,50
    80001e6c:	16f4ac23          	sw	a5,376(s1)
    p->dynamic_priority = 75;
    80001e70:	04b00793          	li	a5,75
    80001e74:	16f4ae23          	sw	a5,380(s1)
}
    80001e78:	8526                	mv	a0,s1
    80001e7a:	60e2                	ld	ra,24(sp)
    80001e7c:	6442                	ld	s0,16(sp)
    80001e7e:	64a2                	ld	s1,8(sp)
    80001e80:	6902                	ld	s2,0(sp)
    80001e82:	6105                	addi	sp,sp,32
    80001e84:	8082                	ret
        freeproc(p);
    80001e86:	8526                	mv	a0,s1
    80001e88:	00000097          	auipc	ra,0x0
    80001e8c:	ece080e7          	jalr	-306(ra) # 80001d56 <freeproc>
        release(&p->lock);
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	f28080e7          	jalr	-216(ra) # 80000dba <release>
        return 0;
    80001e9a:	84ca                	mv	s1,s2
    80001e9c:	bff1                	j	80001e78 <allocproc+0xca>
        freeproc(p);
    80001e9e:	8526                	mv	a0,s1
    80001ea0:	00000097          	auipc	ra,0x0
    80001ea4:	eb6080e7          	jalr	-330(ra) # 80001d56 <freeproc>
        release(&p->lock);
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	f10080e7          	jalr	-240(ra) # 80000dba <release>
        return 0;
    80001eb2:	84ca                	mv	s1,s2
    80001eb4:	b7d1                	j	80001e78 <allocproc+0xca>

0000000080001eb6 <userinit>:
{
    80001eb6:	1101                	addi	sp,sp,-32
    80001eb8:	ec06                	sd	ra,24(sp)
    80001eba:	e822                	sd	s0,16(sp)
    80001ebc:	e426                	sd	s1,8(sp)
    80001ebe:	1000                	addi	s0,sp,32
    p = allocproc();
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	eee080e7          	jalr	-274(ra) # 80001dae <allocproc>
    80001ec8:	84aa                	mv	s1,a0
    initproc = p;
    80001eca:	00007797          	auipc	a5,0x7
    80001ece:	a4a7bf23          	sd	a0,-1442(a5) # 80008928 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ed2:	03400613          	li	a2,52
    80001ed6:	00007597          	auipc	a1,0x7
    80001eda:	9ea58593          	addi	a1,a1,-1558 # 800088c0 <initcode>
    80001ede:	6928                	ld	a0,80(a0)
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	5a6080e7          	jalr	1446(ra) # 80001486 <uvmfirst>
    p->sz = PGSIZE;
    80001ee8:	6785                	lui	a5,0x1
    80001eea:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001eec:	6cb8                	ld	a4,88(s1)
    80001eee:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001ef2:	6cb8                	ld	a4,88(s1)
    80001ef4:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001ef6:	4641                	li	a2,16
    80001ef8:	00006597          	auipc	a1,0x6
    80001efc:	33058593          	addi	a1,a1,816 # 80008228 <digits+0x1e8>
    80001f00:	15848513          	addi	a0,s1,344
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	048080e7          	jalr	72(ra) # 80000f4c <safestrcpy>
    p->cwd = namei("/");
    80001f0c:	00006517          	auipc	a0,0x6
    80001f10:	32c50513          	addi	a0,a0,812 # 80008238 <digits+0x1f8>
    80001f14:	00002097          	auipc	ra,0x2
    80001f18:	776080e7          	jalr	1910(ra) # 8000468a <namei>
    80001f1c:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	e94080e7          	jalr	-364(ra) # 80000dba <release>
}
    80001f2e:	60e2                	ld	ra,24(sp)
    80001f30:	6442                	ld	s0,16(sp)
    80001f32:	64a2                	ld	s1,8(sp)
    80001f34:	6105                	addi	sp,sp,32
    80001f36:	8082                	ret

0000000080001f38 <growproc>:
{
    80001f38:	1101                	addi	sp,sp,-32
    80001f3a:	ec06                	sd	ra,24(sp)
    80001f3c:	e822                	sd	s0,16(sp)
    80001f3e:	e426                	sd	s1,8(sp)
    80001f40:	e04a                	sd	s2,0(sp)
    80001f42:	1000                	addi	s0,sp,32
    80001f44:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	c5e080e7          	jalr	-930(ra) # 80001ba4 <myproc>
    80001f4e:	84aa                	mv	s1,a0
    sz = p->sz;
    80001f50:	652c                	ld	a1,72(a0)
    if (n > 0)
    80001f52:	01204c63          	bgtz	s2,80001f6a <growproc+0x32>
    else if (n < 0)
    80001f56:	02094663          	bltz	s2,80001f82 <growproc+0x4a>
    p->sz = sz;
    80001f5a:	e4ac                	sd	a1,72(s1)
    return 0;
    80001f5c:	4501                	li	a0,0
}
    80001f5e:	60e2                	ld	ra,24(sp)
    80001f60:	6442                	ld	s0,16(sp)
    80001f62:	64a2                	ld	s1,8(sp)
    80001f64:	6902                	ld	s2,0(sp)
    80001f66:	6105                	addi	sp,sp,32
    80001f68:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f6a:	4691                	li	a3,4
    80001f6c:	00b90633          	add	a2,s2,a1
    80001f70:	6928                	ld	a0,80(a0)
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	5ce080e7          	jalr	1486(ra) # 80001540 <uvmalloc>
    80001f7a:	85aa                	mv	a1,a0
    80001f7c:	fd79                	bnez	a0,80001f5a <growproc+0x22>
            return -1;
    80001f7e:	557d                	li	a0,-1
    80001f80:	bff9                	j	80001f5e <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f82:	00b90633          	add	a2,s2,a1
    80001f86:	6928                	ld	a0,80(a0)
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	570080e7          	jalr	1392(ra) # 800014f8 <uvmdealloc>
    80001f90:	85aa                	mv	a1,a0
    80001f92:	b7e1                	j	80001f5a <growproc+0x22>

0000000080001f94 <fork>:
{
    80001f94:	7139                	addi	sp,sp,-64
    80001f96:	fc06                	sd	ra,56(sp)
    80001f98:	f822                	sd	s0,48(sp)
    80001f9a:	f426                	sd	s1,40(sp)
    80001f9c:	f04a                	sd	s2,32(sp)
    80001f9e:	ec4e                	sd	s3,24(sp)
    80001fa0:	e852                	sd	s4,16(sp)
    80001fa2:	e456                	sd	s5,8(sp)
    80001fa4:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	bfe080e7          	jalr	-1026(ra) # 80001ba4 <myproc>
    80001fae:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	dfe080e7          	jalr	-514(ra) # 80001dae <allocproc>
    80001fb8:	10050c63          	beqz	a0,800020d0 <fork+0x13c>
    80001fbc:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fbe:	048ab603          	ld	a2,72(s5)
    80001fc2:	692c                	ld	a1,80(a0)
    80001fc4:	050ab503          	ld	a0,80(s5)
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	6cc080e7          	jalr	1740(ra) # 80001694 <uvmcopy>
    80001fd0:	04054863          	bltz	a0,80002020 <fork+0x8c>
    np->sz = p->sz;
    80001fd4:	048ab783          	ld	a5,72(s5)
    80001fd8:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80001fdc:	058ab683          	ld	a3,88(s5)
    80001fe0:	87b6                	mv	a5,a3
    80001fe2:	058a3703          	ld	a4,88(s4)
    80001fe6:	12068693          	addi	a3,a3,288
    80001fea:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fee:	6788                	ld	a0,8(a5)
    80001ff0:	6b8c                	ld	a1,16(a5)
    80001ff2:	6f90                	ld	a2,24(a5)
    80001ff4:	01073023          	sd	a6,0(a4)
    80001ff8:	e708                	sd	a0,8(a4)
    80001ffa:	eb0c                	sd	a1,16(a4)
    80001ffc:	ef10                	sd	a2,24(a4)
    80001ffe:	02078793          	addi	a5,a5,32
    80002002:	02070713          	addi	a4,a4,32
    80002006:	fed792e3          	bne	a5,a3,80001fea <fork+0x56>
    np->trapframe->a0 = 0;
    8000200a:	058a3783          	ld	a5,88(s4)
    8000200e:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002012:	0d0a8493          	addi	s1,s5,208
    80002016:	0d0a0913          	addi	s2,s4,208
    8000201a:	150a8993          	addi	s3,s5,336
    8000201e:	a00d                	j	80002040 <fork+0xac>
        freeproc(np);
    80002020:	8552                	mv	a0,s4
    80002022:	00000097          	auipc	ra,0x0
    80002026:	d34080e7          	jalr	-716(ra) # 80001d56 <freeproc>
        release(&np->lock);
    8000202a:	8552                	mv	a0,s4
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	d8e080e7          	jalr	-626(ra) # 80000dba <release>
        return -1;
    80002034:	597d                	li	s2,-1
    80002036:	a059                	j	800020bc <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002038:	04a1                	addi	s1,s1,8
    8000203a:	0921                	addi	s2,s2,8
    8000203c:	01348b63          	beq	s1,s3,80002052 <fork+0xbe>
        if (p->ofile[i])
    80002040:	6088                	ld	a0,0(s1)
    80002042:	d97d                	beqz	a0,80002038 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002044:	00003097          	auipc	ra,0x3
    80002048:	cdc080e7          	jalr	-804(ra) # 80004d20 <filedup>
    8000204c:	00a93023          	sd	a0,0(s2)
    80002050:	b7e5                	j	80002038 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002052:	150ab503          	ld	a0,336(s5)
    80002056:	00002097          	auipc	ra,0x2
    8000205a:	e50080e7          	jalr	-432(ra) # 80003ea6 <idup>
    8000205e:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002062:	4641                	li	a2,16
    80002064:	158a8593          	addi	a1,s5,344
    80002068:	158a0513          	addi	a0,s4,344
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	ee0080e7          	jalr	-288(ra) # 80000f4c <safestrcpy>
    pid = np->pid;
    80002074:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002078:	8552                	mv	a0,s4
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	d40080e7          	jalr	-704(ra) # 80000dba <release>
    acquire(&wait_lock);
    80002082:	0022f497          	auipc	s1,0x22f
    80002086:	b4e48493          	addi	s1,s1,-1202 # 80230bd0 <wait_lock>
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c7a080e7          	jalr	-902(ra) # 80000d06 <acquire>
    np->parent = p;
    80002094:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	d20080e7          	jalr	-736(ra) # 80000dba <release>
    acquire(&np->lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	c62080e7          	jalr	-926(ra) # 80000d06 <acquire>
    np->state = RUNNABLE;
    800020ac:	478d                	li	a5,3
    800020ae:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800020b2:	8552                	mv	a0,s4
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	d06080e7          	jalr	-762(ra) # 80000dba <release>
}
    800020bc:	854a                	mv	a0,s2
    800020be:	70e2                	ld	ra,56(sp)
    800020c0:	7442                	ld	s0,48(sp)
    800020c2:	74a2                	ld	s1,40(sp)
    800020c4:	7902                	ld	s2,32(sp)
    800020c6:	69e2                	ld	s3,24(sp)
    800020c8:	6a42                	ld	s4,16(sp)
    800020ca:	6aa2                	ld	s5,8(sp)
    800020cc:	6121                	addi	sp,sp,64
    800020ce:	8082                	ret
        return -1;
    800020d0:	597d                	li	s2,-1
    800020d2:	b7ed                	j	800020bc <fork+0x128>

00000000800020d4 <scheduler>:
{
    800020d4:	7119                	addi	sp,sp,-128
    800020d6:	fc86                	sd	ra,120(sp)
    800020d8:	f8a2                	sd	s0,112(sp)
    800020da:	f4a6                	sd	s1,104(sp)
    800020dc:	f0ca                	sd	s2,96(sp)
    800020de:	ecce                	sd	s3,88(sp)
    800020e0:	e8d2                	sd	s4,80(sp)
    800020e2:	e4d6                	sd	s5,72(sp)
    800020e4:	e0da                	sd	s6,64(sp)
    800020e6:	fc5e                	sd	s7,56(sp)
    800020e8:	f862                	sd	s8,48(sp)
    800020ea:	f466                	sd	s9,40(sp)
    800020ec:	f06a                	sd	s10,32(sp)
    800020ee:	ec6e                	sd	s11,24(sp)
    800020f0:	0100                	addi	s0,sp,128
    800020f2:	8792                	mv	a5,tp
    int id = r_tp();
    800020f4:	2781                	sext.w	a5,a5
    c->proc = 0;
    800020f6:	00779693          	slli	a3,a5,0x7
    800020fa:	0022f717          	auipc	a4,0x22f
    800020fe:	abe70713          	addi	a4,a4,-1346 # 80230bb8 <pid_lock>
    80002102:	9736                	add	a4,a4,a3
    80002104:	02073823          	sd	zero,48(a4)
                swtch(&c->context, &temp->context);
    80002108:	0022f717          	auipc	a4,0x22f
    8000210c:	ae870713          	addi	a4,a4,-1304 # 80230bf0 <cpus+0x8>
    80002110:	9736                	add	a4,a4,a3
    80002112:	f8e43423          	sd	a4,-120(s0)
                    p->rbi = (((3 * p->my_rtime) - p->stime - p->wtime) * 50 / (1 + p->my_rtime + p->stime + p->wtime));
    80002116:	03200d13          	li	s10,50
        for (p = proc; p < &proc[NPROC]; p++)
    8000211a:	00235a17          	auipc	s4,0x235
    8000211e:	2cea0a13          	addi	s4,s4,718 # 802373e8 <tickslock>
                c->proc = temp;
    80002122:	0022fd97          	auipc	s11,0x22f
    80002126:	a96d8d93          	addi	s11,s11,-1386 # 80230bb8 <pid_lock>
    8000212a:	9db6                	add	s11,s11,a3
    8000212c:	aa39                	j	8000224a <scheduler+0x176>
                p->rbi = 25;
    8000212e:	1994a423          	sw	s9,392(s1)
            p->dynamic_priority = p->static_priority + p->rbi;
    80002132:	1784a783          	lw	a5,376(s1)
    80002136:	1884a703          	lw	a4,392(s1)
    8000213a:	9fb9                	addw	a5,a5,a4
    8000213c:	0007871b          	sext.w	a4,a5
            if (p->dynamic_priority > 100)
    80002140:	06eb4563          	blt	s6,a4,800021aa <scheduler+0xd6>
            p->dynamic_priority = p->static_priority + p->rbi;
    80002144:	16f4ae23          	sw	a5,380(s1)
            release(&p->lock);
    80002148:	8526                	mv	a0,s1
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	c70080e7          	jalr	-912(ra) # 80000dba <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002152:	19048493          	addi	s1,s1,400
    80002156:	05448d63          	beq	s1,s4,800021b0 <scheduler+0xdc>
            acquire(&p->lock);
    8000215a:	8526                	mv	a0,s1
    8000215c:	fffff097          	auipc	ra,0xfffff
    80002160:	baa080e7          	jalr	-1110(ra) # 80000d06 <acquire>
            if (p->rbi == -1)
    80002164:	1884a783          	lw	a5,392(s1)
    80002168:	fd2783e3          	beq	a5,s2,8000212e <scheduler+0x5a>
                if ((3 * p->my_rtime) > (p->stime + p->wtime))
    8000216c:	16c4a703          	lw	a4,364(s1)
    80002170:	0017179b          	slliw	a5,a4,0x1
    80002174:	9fb9                	addw	a5,a5,a4
    80002176:	0007859b          	sext.w	a1,a5
    8000217a:	1804a603          	lw	a2,384(s1)
    8000217e:	1844a683          	lw	a3,388(s1)
    80002182:	00d6053b          	addw	a0,a2,a3
    80002186:	00b57f63          	bgeu	a0,a1,800021a4 <scheduler+0xd0>
                    p->rbi = (((3 * p->my_rtime) - p->stime - p->wtime) * 50 / (1 + p->my_rtime + p->stime + p->wtime));
    8000218a:	00d605bb          	addw	a1,a2,a3
    8000218e:	9f8d                	subw	a5,a5,a1
    80002190:	03a787bb          	mulw	a5,a5,s10
    80002194:	2705                	addiw	a4,a4,1
    80002196:	9f31                	addw	a4,a4,a2
    80002198:	9f35                	addw	a4,a4,a3
    8000219a:	02e7d7bb          	divuw	a5,a5,a4
    8000219e:	18f4a423          	sw	a5,392(s1)
    800021a2:	bf41                	j	80002132 <scheduler+0x5e>
                    p->rbi = 0;
    800021a4:	1804a423          	sw	zero,392(s1)
    800021a8:	b769                	j	80002132 <scheduler+0x5e>
                p->dynamic_priority = 100;
    800021aa:	1764ae23          	sw	s6,380(s1)
    800021ae:	bf69                	j	80002148 <scheduler+0x74>
    800021b0:	0022f497          	auipc	s1,0x22f
    800021b4:	e3848493          	addi	s1,s1,-456 # 80230fe8 <proc>
    800021b8:	0022f917          	auipc	s2,0x22f
    800021bc:	fc090913          	addi	s2,s2,-64 # 80231178 <proc+0x190>
        struct proc *temp = 0;
    800021c0:	4c01                	li	s8,0
            if (p->state == RUNNABLE)
    800021c2:	4b8d                	li	s7,3
    800021c4:	a06d                	j	8000226e <scheduler+0x19a>
                if (temp == 0)
    800021c6:	080c0663          	beqz	s8,80002252 <scheduler+0x17e>
                    if (p->dynamic_priority < temp->dynamic_priority)
    800021ca:	fec92703          	lw	a4,-20(s2)
    800021ce:	17cc2783          	lw	a5,380(s8)
    800021d2:	08f74263          	blt	a4,a5,80002256 <scheduler+0x182>
                    else if (p->dynamic_priority == temp->dynamic_priority)
    800021d6:	08f71163          	bne	a4,a5,80002258 <scheduler+0x184>
                        if (p->num_sched < temp->num_sched)
    800021da:	ffc92703          	lw	a4,-4(s2)
    800021de:	18cc2783          	lw	a5,396(s8)
    800021e2:	0cf74663          	blt	a4,a5,800022ae <scheduler+0x1da>
                        else if (p->num_sched == temp->num_sched)
    800021e6:	06f71963          	bne	a4,a5,80002258 <scheduler+0x184>
                            if (p->ctime < temp->ctime)
    800021ea:	fe092703          	lw	a4,-32(s2)
    800021ee:	170c2783          	lw	a5,368(s8)
    800021f2:	06f77363          	bgeu	a4,a5,80002258 <scheduler+0x184>
    800021f6:	8c26                	mv	s8,s1
    800021f8:	a085                	j	80002258 <scheduler+0x184>
            acquire(&temp->lock);
    800021fa:	84e2                	mv	s1,s8
    800021fc:	8562                	mv	a0,s8
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	b08080e7          	jalr	-1272(ra) # 80000d06 <acquire>
            if (temp->state == RUNNABLE)
    80002206:	018c2703          	lw	a4,24(s8)
    8000220a:	478d                	li	a5,3
    8000220c:	02f71a63          	bne	a4,a5,80002240 <scheduler+0x16c>
                temp->num_sched++;
    80002210:	18cc2783          	lw	a5,396(s8)
    80002214:	2785                	addiw	a5,a5,1
    80002216:	18fc2623          	sw	a5,396(s8)
                temp->state = RUNNING;
    8000221a:	4791                	li	a5,4
    8000221c:	00fc2c23          	sw	a5,24(s8)
                p->my_rtime = 0;
    80002220:	1609a623          	sw	zero,364(s3)
                temp->stime = 0;
    80002224:	180c2023          	sw	zero,384(s8)
                c->proc = temp;
    80002228:	038db823          	sd	s8,48(s11)
                swtch(&c->context, &temp->context);
    8000222c:	060c0593          	addi	a1,s8,96
    80002230:	f8843503          	ld	a0,-120(s0)
    80002234:	00001097          	auipc	ra,0x1
    80002238:	a12080e7          	jalr	-1518(ra) # 80002c46 <swtch>
                c->proc = 0;
    8000223c:	020db823          	sd	zero,48(s11)
            release(&temp->lock);
    80002240:	8526                	mv	a0,s1
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	b78080e7          	jalr	-1160(ra) # 80000dba <release>
                p->rbi = 25;
    8000224a:	4ce5                	li	s9,25
            if (p->dynamic_priority > 100)
    8000224c:	06400b13          	li	s6,100
    80002250:	a099                	j	80002296 <scheduler+0x1c2>
    80002252:	8c26                	mv	s8,s1
    80002254:	a011                	j	80002258 <scheduler+0x184>
    80002256:	8c26                	mv	s8,s1
            release(&p->lock);
    80002258:	8556                	mv	a0,s5
    8000225a:	fffff097          	auipc	ra,0xfffff
    8000225e:	b60080e7          	jalr	-1184(ra) # 80000dba <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80002262:	f949fce3          	bgeu	s3,s4,800021fa <scheduler+0x126>
    80002266:	19048493          	addi	s1,s1,400
    8000226a:	19090913          	addi	s2,s2,400
    8000226e:	8aa6                	mv	s5,s1
            acquire(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a94080e7          	jalr	-1388(ra) # 80000d06 <acquire>
            if (p->state == RUNNABLE)
    8000227a:	89ca                	mv	s3,s2
    8000227c:	e8892783          	lw	a5,-376(s2)
    80002280:	f57783e3          	beq	a5,s7,800021c6 <scheduler+0xf2>
            release(&p->lock);
    80002284:	8526                	mv	a0,s1
    80002286:	fffff097          	auipc	ra,0xfffff
    8000228a:	b34080e7          	jalr	-1228(ra) # 80000dba <release>
        for (p = proc; p < &proc[NPROC]; p++)
    8000228e:	fd496ce3          	bltu	s2,s4,80002266 <scheduler+0x192>
        if (temp != 0)
    80002292:	f60c14e3          	bnez	s8,800021fa <scheduler+0x126>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002296:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000229a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000229e:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    800022a2:	0022f497          	auipc	s1,0x22f
    800022a6:	d4648493          	addi	s1,s1,-698 # 80230fe8 <proc>
            if (p->rbi == -1)
    800022aa:	597d                	li	s2,-1
    800022ac:	b57d                	j	8000215a <scheduler+0x86>
    800022ae:	8c26                	mv	s8,s1
    800022b0:	b765                	j	80002258 <scheduler+0x184>

00000000800022b2 <sched>:
{
    800022b2:	7179                	addi	sp,sp,-48
    800022b4:	f406                	sd	ra,40(sp)
    800022b6:	f022                	sd	s0,32(sp)
    800022b8:	ec26                	sd	s1,24(sp)
    800022ba:	e84a                	sd	s2,16(sp)
    800022bc:	e44e                	sd	s3,8(sp)
    800022be:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800022c0:	00000097          	auipc	ra,0x0
    800022c4:	8e4080e7          	jalr	-1820(ra) # 80001ba4 <myproc>
    800022c8:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9c2080e7          	jalr	-1598(ra) # 80000c8c <holding>
    800022d2:	c93d                	beqz	a0,80002348 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022d4:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800022d6:	2781                	sext.w	a5,a5
    800022d8:	079e                	slli	a5,a5,0x7
    800022da:	0022f717          	auipc	a4,0x22f
    800022de:	8de70713          	addi	a4,a4,-1826 # 80230bb8 <pid_lock>
    800022e2:	97ba                	add	a5,a5,a4
    800022e4:	0a87a703          	lw	a4,168(a5)
    800022e8:	4785                	li	a5,1
    800022ea:	06f71763          	bne	a4,a5,80002358 <sched+0xa6>
    if (p->state == RUNNING)
    800022ee:	4c98                	lw	a4,24(s1)
    800022f0:	4791                	li	a5,4
    800022f2:	06f70b63          	beq	a4,a5,80002368 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022fa:	8b89                	andi	a5,a5,2
    if (intr_get())
    800022fc:	efb5                	bnez	a5,80002378 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022fe:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002300:	0022f917          	auipc	s2,0x22f
    80002304:	8b890913          	addi	s2,s2,-1864 # 80230bb8 <pid_lock>
    80002308:	2781                	sext.w	a5,a5
    8000230a:	079e                	slli	a5,a5,0x7
    8000230c:	97ca                	add	a5,a5,s2
    8000230e:	0ac7a983          	lw	s3,172(a5)
    80002312:	8792                	mv	a5,tp
    swtch(&p->context, &mycpu()->context);
    80002314:	2781                	sext.w	a5,a5
    80002316:	079e                	slli	a5,a5,0x7
    80002318:	0022f597          	auipc	a1,0x22f
    8000231c:	8d858593          	addi	a1,a1,-1832 # 80230bf0 <cpus+0x8>
    80002320:	95be                	add	a1,a1,a5
    80002322:	06048513          	addi	a0,s1,96
    80002326:	00001097          	auipc	ra,0x1
    8000232a:	920080e7          	jalr	-1760(ra) # 80002c46 <swtch>
    8000232e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002330:	2781                	sext.w	a5,a5
    80002332:	079e                	slli	a5,a5,0x7
    80002334:	97ca                	add	a5,a5,s2
    80002336:	0b37a623          	sw	s3,172(a5)
}
    8000233a:	70a2                	ld	ra,40(sp)
    8000233c:	7402                	ld	s0,32(sp)
    8000233e:	64e2                	ld	s1,24(sp)
    80002340:	6942                	ld	s2,16(sp)
    80002342:	69a2                	ld	s3,8(sp)
    80002344:	6145                	addi	sp,sp,48
    80002346:	8082                	ret
        panic("sched p->lock");
    80002348:	00006517          	auipc	a0,0x6
    8000234c:	ef850513          	addi	a0,a0,-264 # 80008240 <digits+0x200>
    80002350:	ffffe097          	auipc	ra,0xffffe
    80002354:	1ee080e7          	jalr	494(ra) # 8000053e <panic>
        panic("sched locks");
    80002358:	00006517          	auipc	a0,0x6
    8000235c:	ef850513          	addi	a0,a0,-264 # 80008250 <digits+0x210>
    80002360:	ffffe097          	auipc	ra,0xffffe
    80002364:	1de080e7          	jalr	478(ra) # 8000053e <panic>
        panic("sched running");
    80002368:	00006517          	auipc	a0,0x6
    8000236c:	ef850513          	addi	a0,a0,-264 # 80008260 <digits+0x220>
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	1ce080e7          	jalr	462(ra) # 8000053e <panic>
        panic("sched interruptible");
    80002378:	00006517          	auipc	a0,0x6
    8000237c:	ef850513          	addi	a0,a0,-264 # 80008270 <digits+0x230>
    80002380:	ffffe097          	auipc	ra,0xffffe
    80002384:	1be080e7          	jalr	446(ra) # 8000053e <panic>

0000000080002388 <yield>:
{
    80002388:	1101                	addi	sp,sp,-32
    8000238a:	ec06                	sd	ra,24(sp)
    8000238c:	e822                	sd	s0,16(sp)
    8000238e:	e426                	sd	s1,8(sp)
    80002390:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002392:	00000097          	auipc	ra,0x0
    80002396:	812080e7          	jalr	-2030(ra) # 80001ba4 <myproc>
    8000239a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	96a080e7          	jalr	-1686(ra) # 80000d06 <acquire>
    p->state = RUNNABLE;
    800023a4:	478d                	li	a5,3
    800023a6:	cc9c                	sw	a5,24(s1)
    sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	f0a080e7          	jalr	-246(ra) # 800022b2 <sched>
    release(&p->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	a08080e7          	jalr	-1528(ra) # 80000dba <release>
}
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6105                	addi	sp,sp,32
    800023c2:	8082                	ret

00000000800023c4 <setPriority>:
{
    800023c4:	7139                	addi	sp,sp,-64
    800023c6:	fc06                	sd	ra,56(sp)
    800023c8:	f822                	sd	s0,48(sp)
    800023ca:	f426                	sd	s1,40(sp)
    800023cc:	f04a                	sd	s2,32(sp)
    800023ce:	ec4e                	sd	s3,24(sp)
    800023d0:	e852                	sd	s4,16(sp)
    800023d2:	e456                	sd	s5,8(sp)
    800023d4:	0080                	addi	s0,sp,64
    if (new_priority < 0 || new_priority > 100)
    800023d6:	06400793          	li	a5,100
    800023da:	0cb7e463          	bltu	a5,a1,800024a2 <setPriority+0xde>
    800023de:	892a                	mv	s2,a0
    800023e0:	8a2e                	mv	s4,a1
    for (temp = proc; temp < &proc[NPROC]; temp++)
    800023e2:	0022f497          	auipc	s1,0x22f
    800023e6:	c0648493          	addi	s1,s1,-1018 # 80230fe8 <proc>
    800023ea:	00235997          	auipc	s3,0x235
    800023ee:	ffe98993          	addi	s3,s3,-2 # 802373e8 <tickslock>
    800023f2:	a811                	j	80002406 <setPriority+0x42>
        release(&temp->lock);
    800023f4:	8526                	mv	a0,s1
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	9c4080e7          	jalr	-1596(ra) # 80000dba <release>
    for (temp = proc; temp < &proc[NPROC]; temp++)
    800023fe:	19048493          	addi	s1,s1,400
    80002402:	09348163          	beq	s1,s3,80002484 <setPriority+0xc0>
        acquire(&temp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	8fe080e7          	jalr	-1794(ra) # 80000d06 <acquire>
        if (temp->pid == pid)
    80002410:	589c                	lw	a5,48(s1)
    80002412:	ff2791e3          	bne	a5,s2,800023f4 <setPriority+0x30>
        release(&temp->lock);
    80002416:	8526                	mv	a0,s1
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	9a2080e7          	jalr	-1630(ra) # 80000dba <release>
    acquire(&temp->lock);
    80002420:	89a6                	mv	s3,s1
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	8e2080e7          	jalr	-1822(ra) # 80000d06 <acquire>
    if (temp->rbi == -1)
    8000242c:	1884a703          	lw	a4,392(s1)
    80002430:	57fd                	li	a5,-1
    80002432:	04f70b63          	beq	a4,a5,80002488 <setPriority+0xc4>
    int old_dynamic_priority = temp->dynamic_priority;
    80002436:	17c4aa83          	lw	s5,380(s1)
    int old_priority = temp->static_priority;
    8000243a:	1784a903          	lw	s2,376(s1)
    temp->static_priority = new_priority;
    8000243e:	1744ac23          	sw	s4,376(s1)
    temp->dynamic_priority = new_priority + 25;
    80002442:	2a65                	addiw	s4,s4,25
    80002444:	000a071b          	sext.w	a4,s4
    80002448:	1744ae23          	sw	s4,380(s1)
    temp->rbi = -1;
    8000244c:	57fd                	li	a5,-1
    8000244e:	18f4a423          	sw	a5,392(s1)
    if (temp->dynamic_priority > 100)
    80002452:	06400793          	li	a5,100
    80002456:	00e7d463          	bge	a5,a4,8000245e <setPriority+0x9a>
        temp->dynamic_priority = 100;
    8000245a:	16f4ae23          	sw	a5,380(s1)
    release(&temp->lock);
    8000245e:	854e                	mv	a0,s3
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	95a080e7          	jalr	-1702(ra) # 80000dba <release>
    if (old_dynamic_priority > temp->dynamic_priority)
    80002468:	17c4a783          	lw	a5,380(s1)
    8000246c:	0357c663          	blt	a5,s5,80002498 <setPriority+0xd4>
}
    80002470:	854a                	mv	a0,s2
    80002472:	70e2                	ld	ra,56(sp)
    80002474:	7442                	ld	s0,48(sp)
    80002476:	74a2                	ld	s1,40(sp)
    80002478:	7902                	ld	s2,32(sp)
    8000247a:	69e2                	ld	s3,24(sp)
    8000247c:	6a42                	ld	s4,16(sp)
    8000247e:	6aa2                	ld	s5,8(sp)
    80002480:	6121                	addi	sp,sp,64
    80002482:	8082                	ret
        return -2;
    80002484:	5979                	li	s2,-2
    80002486:	b7ed                	j	80002470 <setPriority+0xac>
        int to_return =temp->static_priority;
    80002488:	1784a903          	lw	s2,376(s1)
        release(&temp->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	92c080e7          	jalr	-1748(ra) # 80000dba <release>
        return to_return;
    80002496:	bfe9                	j	80002470 <setPriority+0xac>
        yield();
    80002498:	00000097          	auipc	ra,0x0
    8000249c:	ef0080e7          	jalr	-272(ra) # 80002388 <yield>
    800024a0:	bfc1                	j	80002470 <setPriority+0xac>
        return -1;
    800024a2:	597d                	li	s2,-1
    800024a4:	b7f1                	j	80002470 <setPriority+0xac>

00000000800024a6 <call_yield>:
{
    800024a6:	1141                	addi	sp,sp,-16
    800024a8:	e406                	sd	ra,8(sp)
    800024aa:	e022                	sd	s0,0(sp)
    800024ac:	0800                	addi	s0,sp,16
    yield();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	eda080e7          	jalr	-294(ra) # 80002388 <yield>
}
    800024b6:	60a2                	ld	ra,8(sp)
    800024b8:	6402                	ld	s0,0(sp)
    800024ba:	0141                	addi	sp,sp,16
    800024bc:	8082                	ret

00000000800024be <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	1800                	addi	s0,sp,48
    800024cc:	89aa                	mv	s3,a0
    800024ce:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	6d4080e7          	jalr	1748(ra) # 80001ba4 <myproc>
    800024d8:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	82c080e7          	jalr	-2004(ra) # 80000d06 <acquire>
    release(lk);
    800024e2:	854a                	mv	a0,s2
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	8d6080e7          	jalr	-1834(ra) # 80000dba <release>

    // Go to sleep.
    p->chan = chan;
    800024ec:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    800024f0:	4789                	li	a5,2
    800024f2:	cc9c                	sw	a5,24(s1)

    sched();
    800024f4:	00000097          	auipc	ra,0x0
    800024f8:	dbe080e7          	jalr	-578(ra) # 800022b2 <sched>

    // Tidy up.
    p->chan = 0;
    800024fc:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	8b8080e7          	jalr	-1864(ra) # 80000dba <release>
    acquire(lk);
    8000250a:	854a                	mv	a0,s2
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	7fa080e7          	jalr	2042(ra) # 80000d06 <acquire>
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6145                	addi	sp,sp,48
    80002520:	8082                	ret

0000000080002522 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002522:	7139                	addi	sp,sp,-64
    80002524:	fc06                	sd	ra,56(sp)
    80002526:	f822                	sd	s0,48(sp)
    80002528:	f426                	sd	s1,40(sp)
    8000252a:	f04a                	sd	s2,32(sp)
    8000252c:	ec4e                	sd	s3,24(sp)
    8000252e:	e852                	sd	s4,16(sp)
    80002530:	e456                	sd	s5,8(sp)
    80002532:	0080                	addi	s0,sp,64
    80002534:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002536:	0022f497          	auipc	s1,0x22f
    8000253a:	ab248493          	addi	s1,s1,-1358 # 80230fe8 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    8000253e:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002540:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002542:	00235917          	auipc	s2,0x235
    80002546:	ea690913          	addi	s2,s2,-346 # 802373e8 <tickslock>
    8000254a:	a811                	j	8000255e <wakeup+0x3c>
            }
            release(&p->lock);
    8000254c:	8526                	mv	a0,s1
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	86c080e7          	jalr	-1940(ra) # 80000dba <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002556:	19048493          	addi	s1,s1,400
    8000255a:	03248663          	beq	s1,s2,80002586 <wakeup+0x64>
        if (p != myproc())
    8000255e:	fffff097          	auipc	ra,0xfffff
    80002562:	646080e7          	jalr	1606(ra) # 80001ba4 <myproc>
    80002566:	fea488e3          	beq	s1,a0,80002556 <wakeup+0x34>
            acquire(&p->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	79a080e7          	jalr	1946(ra) # 80000d06 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002574:	4c9c                	lw	a5,24(s1)
    80002576:	fd379be3          	bne	a5,s3,8000254c <wakeup+0x2a>
    8000257a:	709c                	ld	a5,32(s1)
    8000257c:	fd4798e3          	bne	a5,s4,8000254c <wakeup+0x2a>
                p->state = RUNNABLE;
    80002580:	0154ac23          	sw	s5,24(s1)
    80002584:	b7e1                	j	8000254c <wakeup+0x2a>
        }
    }
}
    80002586:	70e2                	ld	ra,56(sp)
    80002588:	7442                	ld	s0,48(sp)
    8000258a:	74a2                	ld	s1,40(sp)
    8000258c:	7902                	ld	s2,32(sp)
    8000258e:	69e2                	ld	s3,24(sp)
    80002590:	6a42                	ld	s4,16(sp)
    80002592:	6aa2                	ld	s5,8(sp)
    80002594:	6121                	addi	sp,sp,64
    80002596:	8082                	ret

0000000080002598 <reparent>:
{
    80002598:	7179                	addi	sp,sp,-48
    8000259a:	f406                	sd	ra,40(sp)
    8000259c:	f022                	sd	s0,32(sp)
    8000259e:	ec26                	sd	s1,24(sp)
    800025a0:	e84a                	sd	s2,16(sp)
    800025a2:	e44e                	sd	s3,8(sp)
    800025a4:	e052                	sd	s4,0(sp)
    800025a6:	1800                	addi	s0,sp,48
    800025a8:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025aa:	0022f497          	auipc	s1,0x22f
    800025ae:	a3e48493          	addi	s1,s1,-1474 # 80230fe8 <proc>
            pp->parent = initproc;
    800025b2:	00006a17          	auipc	s4,0x6
    800025b6:	376a0a13          	addi	s4,s4,886 # 80008928 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025ba:	00235997          	auipc	s3,0x235
    800025be:	e2e98993          	addi	s3,s3,-466 # 802373e8 <tickslock>
    800025c2:	a029                	j	800025cc <reparent+0x34>
    800025c4:	19048493          	addi	s1,s1,400
    800025c8:	01348d63          	beq	s1,s3,800025e2 <reparent+0x4a>
        if (pp->parent == p)
    800025cc:	7c9c                	ld	a5,56(s1)
    800025ce:	ff279be3          	bne	a5,s2,800025c4 <reparent+0x2c>
            pp->parent = initproc;
    800025d2:	000a3503          	ld	a0,0(s4)
    800025d6:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800025d8:	00000097          	auipc	ra,0x0
    800025dc:	f4a080e7          	jalr	-182(ra) # 80002522 <wakeup>
    800025e0:	b7d5                	j	800025c4 <reparent+0x2c>
}
    800025e2:	70a2                	ld	ra,40(sp)
    800025e4:	7402                	ld	s0,32(sp)
    800025e6:	64e2                	ld	s1,24(sp)
    800025e8:	6942                	ld	s2,16(sp)
    800025ea:	69a2                	ld	s3,8(sp)
    800025ec:	6a02                	ld	s4,0(sp)
    800025ee:	6145                	addi	sp,sp,48
    800025f0:	8082                	ret

00000000800025f2 <exit>:
{
    800025f2:	7179                	addi	sp,sp,-48
    800025f4:	f406                	sd	ra,40(sp)
    800025f6:	f022                	sd	s0,32(sp)
    800025f8:	ec26                	sd	s1,24(sp)
    800025fa:	e84a                	sd	s2,16(sp)
    800025fc:	e44e                	sd	s3,8(sp)
    800025fe:	e052                	sd	s4,0(sp)
    80002600:	1800                	addi	s0,sp,48
    80002602:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002604:	fffff097          	auipc	ra,0xfffff
    80002608:	5a0080e7          	jalr	1440(ra) # 80001ba4 <myproc>
    8000260c:	89aa                	mv	s3,a0
    if (p == initproc)
    8000260e:	00006797          	auipc	a5,0x6
    80002612:	31a7b783          	ld	a5,794(a5) # 80008928 <initproc>
    80002616:	0d050493          	addi	s1,a0,208
    8000261a:	15050913          	addi	s2,a0,336
    8000261e:	02a79363          	bne	a5,a0,80002644 <exit+0x52>
        panic("init exiting");
    80002622:	00006517          	auipc	a0,0x6
    80002626:	c6650513          	addi	a0,a0,-922 # 80008288 <digits+0x248>
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>
            fileclose(f);
    80002632:	00002097          	auipc	ra,0x2
    80002636:	740080e7          	jalr	1856(ra) # 80004d72 <fileclose>
            p->ofile[fd] = 0;
    8000263a:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    8000263e:	04a1                	addi	s1,s1,8
    80002640:	01248563          	beq	s1,s2,8000264a <exit+0x58>
        if (p->ofile[fd])
    80002644:	6088                	ld	a0,0(s1)
    80002646:	f575                	bnez	a0,80002632 <exit+0x40>
    80002648:	bfdd                	j	8000263e <exit+0x4c>
    begin_op();
    8000264a:	00002097          	auipc	ra,0x2
    8000264e:	25c080e7          	jalr	604(ra) # 800048a6 <begin_op>
    iput(p->cwd);
    80002652:	1509b503          	ld	a0,336(s3)
    80002656:	00002097          	auipc	ra,0x2
    8000265a:	a48080e7          	jalr	-1464(ra) # 8000409e <iput>
    end_op();
    8000265e:	00002097          	auipc	ra,0x2
    80002662:	2c8080e7          	jalr	712(ra) # 80004926 <end_op>
    p->cwd = 0;
    80002666:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    8000266a:	0022e497          	auipc	s1,0x22e
    8000266e:	56648493          	addi	s1,s1,1382 # 80230bd0 <wait_lock>
    80002672:	8526                	mv	a0,s1
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	692080e7          	jalr	1682(ra) # 80000d06 <acquire>
    reparent(p);
    8000267c:	854e                	mv	a0,s3
    8000267e:	00000097          	auipc	ra,0x0
    80002682:	f1a080e7          	jalr	-230(ra) # 80002598 <reparent>
    wakeup(p->parent);
    80002686:	0389b503          	ld	a0,56(s3)
    8000268a:	00000097          	auipc	ra,0x0
    8000268e:	e98080e7          	jalr	-360(ra) # 80002522 <wakeup>
    acquire(&p->lock);
    80002692:	854e                	mv	a0,s3
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	672080e7          	jalr	1650(ra) # 80000d06 <acquire>
    p->xstate = status;
    8000269c:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800026a0:	4795                	li	a5,5
    800026a2:	00f9ac23          	sw	a5,24(s3)
    p->etime = ticks;
    800026a6:	00006797          	auipc	a5,0x6
    800026aa:	28a7a783          	lw	a5,650(a5) # 80008930 <ticks>
    800026ae:	16f9aa23          	sw	a5,372(s3)
    release(&wait_lock);
    800026b2:	8526                	mv	a0,s1
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	706080e7          	jalr	1798(ra) # 80000dba <release>
    sched();
    800026bc:	00000097          	auipc	ra,0x0
    800026c0:	bf6080e7          	jalr	-1034(ra) # 800022b2 <sched>
    panic("zombie exit");
    800026c4:	00006517          	auipc	a0,0x6
    800026c8:	bd450513          	addi	a0,a0,-1068 # 80008298 <digits+0x258>
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>

00000000800026d4 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026d4:	7179                	addi	sp,sp,-48
    800026d6:	f406                	sd	ra,40(sp)
    800026d8:	f022                	sd	s0,32(sp)
    800026da:	ec26                	sd	s1,24(sp)
    800026dc:	e84a                	sd	s2,16(sp)
    800026de:	e44e                	sd	s3,8(sp)
    800026e0:	1800                	addi	s0,sp,48
    800026e2:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800026e4:	0022f497          	auipc	s1,0x22f
    800026e8:	90448493          	addi	s1,s1,-1788 # 80230fe8 <proc>
    800026ec:	00235997          	auipc	s3,0x235
    800026f0:	cfc98993          	addi	s3,s3,-772 # 802373e8 <tickslock>
    {
        acquire(&p->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	610080e7          	jalr	1552(ra) # 80000d06 <acquire>
        if (p->pid == pid)
    800026fe:	589c                	lw	a5,48(s1)
    80002700:	01278d63          	beq	a5,s2,8000271a <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002704:	8526                	mv	a0,s1
    80002706:	ffffe097          	auipc	ra,0xffffe
    8000270a:	6b4080e7          	jalr	1716(ra) # 80000dba <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000270e:	19048493          	addi	s1,s1,400
    80002712:	ff3491e3          	bne	s1,s3,800026f4 <kill+0x20>
    }
    return -1;
    80002716:	557d                	li	a0,-1
    80002718:	a829                	j	80002732 <kill+0x5e>
            p->killed = 1;
    8000271a:	4785                	li	a5,1
    8000271c:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    8000271e:	4c98                	lw	a4,24(s1)
    80002720:	4789                	li	a5,2
    80002722:	00f70f63          	beq	a4,a5,80002740 <kill+0x6c>
            release(&p->lock);
    80002726:	8526                	mv	a0,s1
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	692080e7          	jalr	1682(ra) # 80000dba <release>
            return 0;
    80002730:	4501                	li	a0,0
}
    80002732:	70a2                	ld	ra,40(sp)
    80002734:	7402                	ld	s0,32(sp)
    80002736:	64e2                	ld	s1,24(sp)
    80002738:	6942                	ld	s2,16(sp)
    8000273a:	69a2                	ld	s3,8(sp)
    8000273c:	6145                	addi	sp,sp,48
    8000273e:	8082                	ret
                p->state = RUNNABLE;
    80002740:	478d                	li	a5,3
    80002742:	cc9c                	sw	a5,24(s1)
    80002744:	b7cd                	j	80002726 <kill+0x52>

0000000080002746 <setkilled>:

void setkilled(struct proc *p)
{
    80002746:	1101                	addi	sp,sp,-32
    80002748:	ec06                	sd	ra,24(sp)
    8000274a:	e822                	sd	s0,16(sp)
    8000274c:	e426                	sd	s1,8(sp)
    8000274e:	1000                	addi	s0,sp,32
    80002750:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	5b4080e7          	jalr	1460(ra) # 80000d06 <acquire>
    p->killed = 1;
    8000275a:	4785                	li	a5,1
    8000275c:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	65a080e7          	jalr	1626(ra) # 80000dba <release>
}
    80002768:	60e2                	ld	ra,24(sp)
    8000276a:	6442                	ld	s0,16(sp)
    8000276c:	64a2                	ld	s1,8(sp)
    8000276e:	6105                	addi	sp,sp,32
    80002770:	8082                	ret

0000000080002772 <killed>:

int killed(struct proc *p)
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	e04a                	sd	s2,0(sp)
    8000277c:	1000                	addi	s0,sp,32
    8000277e:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	586080e7          	jalr	1414(ra) # 80000d06 <acquire>
    k = p->killed;
    80002788:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000278c:	8526                	mv	a0,s1
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	62c080e7          	jalr	1580(ra) # 80000dba <release>
    return k;
}
    80002796:	854a                	mv	a0,s2
    80002798:	60e2                	ld	ra,24(sp)
    8000279a:	6442                	ld	s0,16(sp)
    8000279c:	64a2                	ld	s1,8(sp)
    8000279e:	6902                	ld	s2,0(sp)
    800027a0:	6105                	addi	sp,sp,32
    800027a2:	8082                	ret

00000000800027a4 <wait>:
{
    800027a4:	715d                	addi	sp,sp,-80
    800027a6:	e486                	sd	ra,72(sp)
    800027a8:	e0a2                	sd	s0,64(sp)
    800027aa:	fc26                	sd	s1,56(sp)
    800027ac:	f84a                	sd	s2,48(sp)
    800027ae:	f44e                	sd	s3,40(sp)
    800027b0:	f052                	sd	s4,32(sp)
    800027b2:	ec56                	sd	s5,24(sp)
    800027b4:	e85a                	sd	s6,16(sp)
    800027b6:	e45e                	sd	s7,8(sp)
    800027b8:	e062                	sd	s8,0(sp)
    800027ba:	0880                	addi	s0,sp,80
    800027bc:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	3e6080e7          	jalr	998(ra) # 80001ba4 <myproc>
    800027c6:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800027c8:	0022e517          	auipc	a0,0x22e
    800027cc:	40850513          	addi	a0,a0,1032 # 80230bd0 <wait_lock>
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	536080e7          	jalr	1334(ra) # 80000d06 <acquire>
        havekids = 0;
    800027d8:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800027da:	4a15                	li	s4,5
                havekids = 1;
    800027dc:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027de:	00235997          	auipc	s3,0x235
    800027e2:	c0a98993          	addi	s3,s3,-1014 # 802373e8 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027e6:	0022ec17          	auipc	s8,0x22e
    800027ea:	3eac0c13          	addi	s8,s8,1002 # 80230bd0 <wait_lock>
        havekids = 0;
    800027ee:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027f0:	0022e497          	auipc	s1,0x22e
    800027f4:	7f848493          	addi	s1,s1,2040 # 80230fe8 <proc>
    800027f8:	a0bd                	j	80002866 <wait+0xc2>
                    pid = pp->pid;
    800027fa:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027fe:	000b0e63          	beqz	s6,8000281a <wait+0x76>
    80002802:	4691                	li	a3,4
    80002804:	02c48613          	addi	a2,s1,44
    80002808:	85da                	mv	a1,s6
    8000280a:	05093503          	ld	a0,80(s2)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	fd0080e7          	jalr	-48(ra) # 800017de <copyout>
    80002816:	02054563          	bltz	a0,80002840 <wait+0x9c>
                    freeproc(pp);
    8000281a:	8526                	mv	a0,s1
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	53a080e7          	jalr	1338(ra) # 80001d56 <freeproc>
                    release(&pp->lock);
    80002824:	8526                	mv	a0,s1
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	594080e7          	jalr	1428(ra) # 80000dba <release>
                    release(&wait_lock);
    8000282e:	0022e517          	auipc	a0,0x22e
    80002832:	3a250513          	addi	a0,a0,930 # 80230bd0 <wait_lock>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	584080e7          	jalr	1412(ra) # 80000dba <release>
                    return pid;
    8000283e:	a0b5                	j	800028aa <wait+0x106>
                        release(&pp->lock);
    80002840:	8526                	mv	a0,s1
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	578080e7          	jalr	1400(ra) # 80000dba <release>
                        release(&wait_lock);
    8000284a:	0022e517          	auipc	a0,0x22e
    8000284e:	38650513          	addi	a0,a0,902 # 80230bd0 <wait_lock>
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	568080e7          	jalr	1384(ra) # 80000dba <release>
                        return -1;
    8000285a:	59fd                	li	s3,-1
    8000285c:	a0b9                	j	800028aa <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000285e:	19048493          	addi	s1,s1,400
    80002862:	03348463          	beq	s1,s3,8000288a <wait+0xe6>
            if (pp->parent == p)
    80002866:	7c9c                	ld	a5,56(s1)
    80002868:	ff279be3          	bne	a5,s2,8000285e <wait+0xba>
                acquire(&pp->lock);
    8000286c:	8526                	mv	a0,s1
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	498080e7          	jalr	1176(ra) # 80000d06 <acquire>
                if (pp->state == ZOMBIE)
    80002876:	4c9c                	lw	a5,24(s1)
    80002878:	f94781e3          	beq	a5,s4,800027fa <wait+0x56>
                release(&pp->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	53c080e7          	jalr	1340(ra) # 80000dba <release>
                havekids = 1;
    80002886:	8756                	mv	a4,s5
    80002888:	bfd9                	j	8000285e <wait+0xba>
        if (!havekids || killed(p))
    8000288a:	c719                	beqz	a4,80002898 <wait+0xf4>
    8000288c:	854a                	mv	a0,s2
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	ee4080e7          	jalr	-284(ra) # 80002772 <killed>
    80002896:	c51d                	beqz	a0,800028c4 <wait+0x120>
            release(&wait_lock);
    80002898:	0022e517          	auipc	a0,0x22e
    8000289c:	33850513          	addi	a0,a0,824 # 80230bd0 <wait_lock>
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	51a080e7          	jalr	1306(ra) # 80000dba <release>
            return -1;
    800028a8:	59fd                	li	s3,-1
}
    800028aa:	854e                	mv	a0,s3
    800028ac:	60a6                	ld	ra,72(sp)
    800028ae:	6406                	ld	s0,64(sp)
    800028b0:	74e2                	ld	s1,56(sp)
    800028b2:	7942                	ld	s2,48(sp)
    800028b4:	79a2                	ld	s3,40(sp)
    800028b6:	7a02                	ld	s4,32(sp)
    800028b8:	6ae2                	ld	s5,24(sp)
    800028ba:	6b42                	ld	s6,16(sp)
    800028bc:	6ba2                	ld	s7,8(sp)
    800028be:	6c02                	ld	s8,0(sp)
    800028c0:	6161                	addi	sp,sp,80
    800028c2:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    800028c4:	85e2                	mv	a1,s8
    800028c6:	854a                	mv	a0,s2
    800028c8:	00000097          	auipc	ra,0x0
    800028cc:	bf6080e7          	jalr	-1034(ra) # 800024be <sleep>
        havekids = 0;
    800028d0:	bf39                	j	800027ee <wait+0x4a>

00000000800028d2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028d2:	7179                	addi	sp,sp,-48
    800028d4:	f406                	sd	ra,40(sp)
    800028d6:	f022                	sd	s0,32(sp)
    800028d8:	ec26                	sd	s1,24(sp)
    800028da:	e84a                	sd	s2,16(sp)
    800028dc:	e44e                	sd	s3,8(sp)
    800028de:	e052                	sd	s4,0(sp)
    800028e0:	1800                	addi	s0,sp,48
    800028e2:	84aa                	mv	s1,a0
    800028e4:	892e                	mv	s2,a1
    800028e6:	89b2                	mv	s3,a2
    800028e8:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028ea:	fffff097          	auipc	ra,0xfffff
    800028ee:	2ba080e7          	jalr	698(ra) # 80001ba4 <myproc>
    if (user_dst)
    800028f2:	c08d                	beqz	s1,80002914 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800028f4:	86d2                	mv	a3,s4
    800028f6:	864e                	mv	a2,s3
    800028f8:	85ca                	mv	a1,s2
    800028fa:	6928                	ld	a0,80(a0)
    800028fc:	fffff097          	auipc	ra,0xfffff
    80002900:	ee2080e7          	jalr	-286(ra) # 800017de <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002904:	70a2                	ld	ra,40(sp)
    80002906:	7402                	ld	s0,32(sp)
    80002908:	64e2                	ld	s1,24(sp)
    8000290a:	6942                	ld	s2,16(sp)
    8000290c:	69a2                	ld	s3,8(sp)
    8000290e:	6a02                	ld	s4,0(sp)
    80002910:	6145                	addi	sp,sp,48
    80002912:	8082                	ret
        memmove((char *)dst, src, len);
    80002914:	000a061b          	sext.w	a2,s4
    80002918:	85ce                	mv	a1,s3
    8000291a:	854a                	mv	a0,s2
    8000291c:	ffffe097          	auipc	ra,0xffffe
    80002920:	542080e7          	jalr	1346(ra) # 80000e5e <memmove>
        return 0;
    80002924:	8526                	mv	a0,s1
    80002926:	bff9                	j	80002904 <either_copyout+0x32>

0000000080002928 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002928:	7179                	addi	sp,sp,-48
    8000292a:	f406                	sd	ra,40(sp)
    8000292c:	f022                	sd	s0,32(sp)
    8000292e:	ec26                	sd	s1,24(sp)
    80002930:	e84a                	sd	s2,16(sp)
    80002932:	e44e                	sd	s3,8(sp)
    80002934:	e052                	sd	s4,0(sp)
    80002936:	1800                	addi	s0,sp,48
    80002938:	892a                	mv	s2,a0
    8000293a:	84ae                	mv	s1,a1
    8000293c:	89b2                	mv	s3,a2
    8000293e:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002940:	fffff097          	auipc	ra,0xfffff
    80002944:	264080e7          	jalr	612(ra) # 80001ba4 <myproc>
    if (user_src)
    80002948:	c08d                	beqz	s1,8000296a <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    8000294a:	86d2                	mv	a3,s4
    8000294c:	864e                	mv	a2,s3
    8000294e:	85ca                	mv	a1,s2
    80002950:	6928                	ld	a0,80(a0)
    80002952:	fffff097          	auipc	ra,0xfffff
    80002956:	f9a080e7          	jalr	-102(ra) # 800018ec <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    8000295a:	70a2                	ld	ra,40(sp)
    8000295c:	7402                	ld	s0,32(sp)
    8000295e:	64e2                	ld	s1,24(sp)
    80002960:	6942                	ld	s2,16(sp)
    80002962:	69a2                	ld	s3,8(sp)
    80002964:	6a02                	ld	s4,0(sp)
    80002966:	6145                	addi	sp,sp,48
    80002968:	8082                	ret
        memmove(dst, (char *)src, len);
    8000296a:	000a061b          	sext.w	a2,s4
    8000296e:	85ce                	mv	a1,s3
    80002970:	854a                	mv	a0,s2
    80002972:	ffffe097          	auipc	ra,0xffffe
    80002976:	4ec080e7          	jalr	1260(ra) # 80000e5e <memmove>
        return 0;
    8000297a:	8526                	mv	a0,s1
    8000297c:	bff9                	j	8000295a <either_copyin+0x32>

000000008000297e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000297e:	715d                	addi	sp,sp,-80
    80002980:	e486                	sd	ra,72(sp)
    80002982:	e0a2                	sd	s0,64(sp)
    80002984:	fc26                	sd	s1,56(sp)
    80002986:	f84a                	sd	s2,48(sp)
    80002988:	f44e                	sd	s3,40(sp)
    8000298a:	f052                	sd	s4,32(sp)
    8000298c:	ec56                	sd	s5,24(sp)
    8000298e:	e85a                	sd	s6,16(sp)
    80002990:	e45e                	sd	s7,8(sp)
    80002992:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002994:	00006517          	auipc	a0,0x6
    80002998:	93450513          	addi	a0,a0,-1740 # 800082c8 <digits+0x288>
    8000299c:	ffffe097          	auipc	ra,0xffffe
    800029a0:	bec080e7          	jalr	-1044(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029a4:	0022e497          	auipc	s1,0x22e
    800029a8:	79c48493          	addi	s1,s1,1948 # 80231140 <proc+0x158>
    800029ac:	00235917          	auipc	s2,0x235
    800029b0:	b9490913          	addi	s2,s2,-1132 # 80237540 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029b4:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800029b6:	00006997          	auipc	s3,0x6
    800029ba:	8f298993          	addi	s3,s3,-1806 # 800082a8 <digits+0x268>
        printf("%d %s %s", p->pid, state, p->name);
    800029be:	00006a97          	auipc	s5,0x6
    800029c2:	8f2a8a93          	addi	s5,s5,-1806 # 800082b0 <digits+0x270>
        printf("\n");
    800029c6:	00006a17          	auipc	s4,0x6
    800029ca:	902a0a13          	addi	s4,s4,-1790 # 800082c8 <digits+0x288>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029ce:	00006b97          	auipc	s7,0x6
    800029d2:	932b8b93          	addi	s7,s7,-1742 # 80008300 <states.0>
    800029d6:	a00d                	j	800029f8 <procdump+0x7a>
        printf("%d %s %s", p->pid, state, p->name);
    800029d8:	ed86a583          	lw	a1,-296(a3)
    800029dc:	8556                	mv	a0,s5
    800029de:	ffffe097          	auipc	ra,0xffffe
    800029e2:	baa080e7          	jalr	-1110(ra) # 80000588 <printf>
        printf("\n");
    800029e6:	8552                	mv	a0,s4
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	ba0080e7          	jalr	-1120(ra) # 80000588 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029f0:	19048493          	addi	s1,s1,400
    800029f4:	03248163          	beq	s1,s2,80002a16 <procdump+0x98>
        if (p->state == UNUSED)
    800029f8:	86a6                	mv	a3,s1
    800029fa:	ec04a783          	lw	a5,-320(s1)
    800029fe:	dbed                	beqz	a5,800029f0 <procdump+0x72>
            state = "???";
    80002a00:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a02:	fcfb6be3          	bltu	s6,a5,800029d8 <procdump+0x5a>
    80002a06:	1782                	slli	a5,a5,0x20
    80002a08:	9381                	srli	a5,a5,0x20
    80002a0a:	078e                	slli	a5,a5,0x3
    80002a0c:	97de                	add	a5,a5,s7
    80002a0e:	6390                	ld	a2,0(a5)
    80002a10:	f661                	bnez	a2,800029d8 <procdump+0x5a>
            state = "???";
    80002a12:	864e                	mv	a2,s3
    80002a14:	b7d1                	j	800029d8 <procdump+0x5a>
    }
}
    80002a16:	60a6                	ld	ra,72(sp)
    80002a18:	6406                	ld	s0,64(sp)
    80002a1a:	74e2                	ld	s1,56(sp)
    80002a1c:	7942                	ld	s2,48(sp)
    80002a1e:	79a2                	ld	s3,40(sp)
    80002a20:	7a02                	ld	s4,32(sp)
    80002a22:	6ae2                	ld	s5,24(sp)
    80002a24:	6b42                	ld	s6,16(sp)
    80002a26:	6ba2                	ld	s7,8(sp)
    80002a28:	6161                	addi	sp,sp,80
    80002a2a:	8082                	ret

0000000080002a2c <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002a2c:	711d                	addi	sp,sp,-96
    80002a2e:	ec86                	sd	ra,88(sp)
    80002a30:	e8a2                	sd	s0,80(sp)
    80002a32:	e4a6                	sd	s1,72(sp)
    80002a34:	e0ca                	sd	s2,64(sp)
    80002a36:	fc4e                	sd	s3,56(sp)
    80002a38:	f852                	sd	s4,48(sp)
    80002a3a:	f456                	sd	s5,40(sp)
    80002a3c:	f05a                	sd	s6,32(sp)
    80002a3e:	ec5e                	sd	s7,24(sp)
    80002a40:	e862                	sd	s8,16(sp)
    80002a42:	e466                	sd	s9,8(sp)
    80002a44:	e06a                	sd	s10,0(sp)
    80002a46:	1080                	addi	s0,sp,96
    80002a48:	8b2a                	mv	s6,a0
    80002a4a:	8bae                	mv	s7,a1
    80002a4c:	8c32                	mv	s8,a2
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	156080e7          	jalr	342(ra) # 80001ba4 <myproc>
    80002a56:	892a                	mv	s2,a0

    acquire(&wait_lock);
    80002a58:	0022e517          	auipc	a0,0x22e
    80002a5c:	17850513          	addi	a0,a0,376 # 80230bd0 <wait_lock>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	2a6080e7          	jalr	678(ra) # 80000d06 <acquire>

    for (;;)
    {
        // Scan through table looking for exited children.
        havekids = 0;
    80002a68:	4c81                	li	s9,0
            {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == ZOMBIE)
    80002a6a:	4a15                	li	s4,5
                havekids = 1;
    80002a6c:	4a85                	li	s5,1
        for (np = proc; np < &proc[NPROC]; np++)
    80002a6e:	00235997          	auipc	s3,0x235
    80002a72:	97a98993          	addi	s3,s3,-1670 # 802373e8 <tickslock>
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002a76:	0022ed17          	auipc	s10,0x22e
    80002a7a:	15ad0d13          	addi	s10,s10,346 # 80230bd0 <wait_lock>
        havekids = 0;
    80002a7e:	8766                	mv	a4,s9
        for (np = proc; np < &proc[NPROC]; np++)
    80002a80:	0022e497          	auipc	s1,0x22e
    80002a84:	56848493          	addi	s1,s1,1384 # 80230fe8 <proc>
    80002a88:	a059                	j	80002b0e <waitx+0xe2>
                    pid = np->pid;
    80002a8a:	0304a983          	lw	s3,48(s1)
                    *rtime = np->rtime;
    80002a8e:	1684a703          	lw	a4,360(s1)
    80002a92:	00ec2023          	sw	a4,0(s8)
                    *wtime = np->etime - np->ctime - np->rtime;
    80002a96:	1704a783          	lw	a5,368(s1)
    80002a9a:	9f3d                	addw	a4,a4,a5
    80002a9c:	1744a783          	lw	a5,372(s1)
    80002aa0:	9f99                	subw	a5,a5,a4
    80002aa2:	00fba023          	sw	a5,0(s7)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002aa6:	000b0e63          	beqz	s6,80002ac2 <waitx+0x96>
    80002aaa:	4691                	li	a3,4
    80002aac:	02c48613          	addi	a2,s1,44
    80002ab0:	85da                	mv	a1,s6
    80002ab2:	05093503          	ld	a0,80(s2)
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	d28080e7          	jalr	-728(ra) # 800017de <copyout>
    80002abe:	02054563          	bltz	a0,80002ae8 <waitx+0xbc>
                    freeproc(np);
    80002ac2:	8526                	mv	a0,s1
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	292080e7          	jalr	658(ra) # 80001d56 <freeproc>
                    release(&np->lock);
    80002acc:	8526                	mv	a0,s1
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	2ec080e7          	jalr	748(ra) # 80000dba <release>
                    release(&wait_lock);
    80002ad6:	0022e517          	auipc	a0,0x22e
    80002ada:	0fa50513          	addi	a0,a0,250 # 80230bd0 <wait_lock>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	2dc080e7          	jalr	732(ra) # 80000dba <release>
                    return pid;
    80002ae6:	a09d                	j	80002b4c <waitx+0x120>
                        release(&np->lock);
    80002ae8:	8526                	mv	a0,s1
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	2d0080e7          	jalr	720(ra) # 80000dba <release>
                        release(&wait_lock);
    80002af2:	0022e517          	auipc	a0,0x22e
    80002af6:	0de50513          	addi	a0,a0,222 # 80230bd0 <wait_lock>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	2c0080e7          	jalr	704(ra) # 80000dba <release>
                        return -1;
    80002b02:	59fd                	li	s3,-1
    80002b04:	a0a1                	j	80002b4c <waitx+0x120>
        for (np = proc; np < &proc[NPROC]; np++)
    80002b06:	19048493          	addi	s1,s1,400
    80002b0a:	03348463          	beq	s1,s3,80002b32 <waitx+0x106>
            if (np->parent == p)
    80002b0e:	7c9c                	ld	a5,56(s1)
    80002b10:	ff279be3          	bne	a5,s2,80002b06 <waitx+0xda>
                acquire(&np->lock);
    80002b14:	8526                	mv	a0,s1
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	1f0080e7          	jalr	496(ra) # 80000d06 <acquire>
                if (np->state == ZOMBIE)
    80002b1e:	4c9c                	lw	a5,24(s1)
    80002b20:	f74785e3          	beq	a5,s4,80002a8a <waitx+0x5e>
                release(&np->lock);
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	294080e7          	jalr	660(ra) # 80000dba <release>
                havekids = 1;
    80002b2e:	8756                	mv	a4,s5
    80002b30:	bfd9                	j	80002b06 <waitx+0xda>
        if (!havekids || p->killed)
    80002b32:	c701                	beqz	a4,80002b3a <waitx+0x10e>
    80002b34:	02892783          	lw	a5,40(s2)
    80002b38:	cb8d                	beqz	a5,80002b6a <waitx+0x13e>
            release(&wait_lock);
    80002b3a:	0022e517          	auipc	a0,0x22e
    80002b3e:	09650513          	addi	a0,a0,150 # 80230bd0 <wait_lock>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	278080e7          	jalr	632(ra) # 80000dba <release>
            return -1;
    80002b4a:	59fd                	li	s3,-1
    }
}
    80002b4c:	854e                	mv	a0,s3
    80002b4e:	60e6                	ld	ra,88(sp)
    80002b50:	6446                	ld	s0,80(sp)
    80002b52:	64a6                	ld	s1,72(sp)
    80002b54:	6906                	ld	s2,64(sp)
    80002b56:	79e2                	ld	s3,56(sp)
    80002b58:	7a42                	ld	s4,48(sp)
    80002b5a:	7aa2                	ld	s5,40(sp)
    80002b5c:	7b02                	ld	s6,32(sp)
    80002b5e:	6be2                	ld	s7,24(sp)
    80002b60:	6c42                	ld	s8,16(sp)
    80002b62:	6ca2                	ld	s9,8(sp)
    80002b64:	6d02                	ld	s10,0(sp)
    80002b66:	6125                	addi	sp,sp,96
    80002b68:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002b6a:	85ea                	mv	a1,s10
    80002b6c:	854a                	mv	a0,s2
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	950080e7          	jalr	-1712(ra) # 800024be <sleep>
        havekids = 0;
    80002b76:	b721                	j	80002a7e <waitx+0x52>

0000000080002b78 <update_time>:

void update_time()
{
    80002b78:	715d                	addi	sp,sp,-80
    80002b7a:	e486                	sd	ra,72(sp)
    80002b7c:	e0a2                	sd	s0,64(sp)
    80002b7e:	fc26                	sd	s1,56(sp)
    80002b80:	f84a                	sd	s2,48(sp)
    80002b82:	f44e                	sd	s3,40(sp)
    80002b84:	f052                	sd	s4,32(sp)
    80002b86:	ec56                	sd	s5,24(sp)
    80002b88:	e85a                	sd	s6,16(sp)
    80002b8a:	e45e                	sd	s7,8(sp)
    80002b8c:	e062                	sd	s8,0(sp)
    80002b8e:	0880                	addi	s0,sp,80
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++)
    80002b90:	0022e497          	auipc	s1,0x22e
    80002b94:	45848493          	addi	s1,s1,1112 # 80230fe8 <proc>
    {
        acquire(&p->lock);
        if (p->state == RUNNING)
    80002b98:	4a11                	li	s4,4
        {
            p->rtime++;
            p->my_rtime++;
            // p->stime = 0;
        }
        if (p->state == SLEEPING)
    80002b9a:	4a89                	li	s5,2
        {
            p->stime++;
        }
        if (p->state == RUNNABLE)
    80002b9c:	4b0d                	li	s6,3
        {
            p->wtime++;
            // p->stime = 0;
        }
        if (p->pid >3 && p->pid<=13)
    80002b9e:	49a5                	li	s3,9
        {
            printf("%d %d %d\n",p->pid,p->dynamic_priority,ticks);
    80002ba0:	00006c17          	auipc	s8,0x6
    80002ba4:	d90c0c13          	addi	s8,s8,-624 # 80008930 <ticks>
    80002ba8:	00005b97          	auipc	s7,0x5
    80002bac:	718b8b93          	addi	s7,s7,1816 # 800082c0 <digits+0x280>
    for (p = proc; p < &proc[NPROC]; p++)
    80002bb0:	00235917          	auipc	s2,0x235
    80002bb4:	83890913          	addi	s2,s2,-1992 # 802373e8 <tickslock>
    80002bb8:	a80d                	j	80002bea <update_time+0x72>
            p->rtime++;
    80002bba:	1684a783          	lw	a5,360(s1)
    80002bbe:	2785                	addiw	a5,a5,1
    80002bc0:	16f4a423          	sw	a5,360(s1)
            p->my_rtime++;
    80002bc4:	16c4a783          	lw	a5,364(s1)
    80002bc8:	2785                	addiw	a5,a5,1
    80002bca:	16f4a623          	sw	a5,364(s1)
        if (p->pid >3 && p->pid<=13)
    80002bce:	588c                	lw	a1,48(s1)
    80002bd0:	ffc5879b          	addiw	a5,a1,-4
    80002bd4:	04f9f363          	bgeu	s3,a5,80002c1a <update_time+0xa2>
        }
        
        release(&p->lock);
    80002bd8:	8526                	mv	a0,s1
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	1e0080e7          	jalr	480(ra) # 80000dba <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002be2:	19048493          	addi	s1,s1,400
    80002be6:	05248463          	beq	s1,s2,80002c2e <update_time+0xb6>
        acquire(&p->lock);
    80002bea:	8526                	mv	a0,s1
    80002bec:	ffffe097          	auipc	ra,0xffffe
    80002bf0:	11a080e7          	jalr	282(ra) # 80000d06 <acquire>
        if (p->state == RUNNING)
    80002bf4:	4c9c                	lw	a5,24(s1)
    80002bf6:	fd4782e3          	beq	a5,s4,80002bba <update_time+0x42>
        if (p->state == SLEEPING)
    80002bfa:	01579863          	bne	a5,s5,80002c0a <update_time+0x92>
            p->stime++;
    80002bfe:	1804a783          	lw	a5,384(s1)
    80002c02:	2785                	addiw	a5,a5,1
    80002c04:	18f4a023          	sw	a5,384(s1)
        if (p->state == RUNNABLE)
    80002c08:	b7d9                	j	80002bce <update_time+0x56>
    80002c0a:	fd6792e3          	bne	a5,s6,80002bce <update_time+0x56>
            p->wtime++;
    80002c0e:	1844a783          	lw	a5,388(s1)
    80002c12:	2785                	addiw	a5,a5,1
    80002c14:	18f4a223          	sw	a5,388(s1)
    80002c18:	bf5d                	j	80002bce <update_time+0x56>
            printf("%d %d %d\n",p->pid,p->dynamic_priority,ticks);
    80002c1a:	000c2683          	lw	a3,0(s8)
    80002c1e:	17c4a603          	lw	a2,380(s1)
    80002c22:	855e                	mv	a0,s7
    80002c24:	ffffe097          	auipc	ra,0xffffe
    80002c28:	964080e7          	jalr	-1692(ra) # 80000588 <printf>
    80002c2c:	b775                	j	80002bd8 <update_time+0x60>
    }
    80002c2e:	60a6                	ld	ra,72(sp)
    80002c30:	6406                	ld	s0,64(sp)
    80002c32:	74e2                	ld	s1,56(sp)
    80002c34:	7942                	ld	s2,48(sp)
    80002c36:	79a2                	ld	s3,40(sp)
    80002c38:	7a02                	ld	s4,32(sp)
    80002c3a:	6ae2                	ld	s5,24(sp)
    80002c3c:	6b42                	ld	s6,16(sp)
    80002c3e:	6ba2                	ld	s7,8(sp)
    80002c40:	6c02                	ld	s8,0(sp)
    80002c42:	6161                	addi	sp,sp,80
    80002c44:	8082                	ret

0000000080002c46 <swtch>:
    80002c46:	00153023          	sd	ra,0(a0)
    80002c4a:	00253423          	sd	sp,8(a0)
    80002c4e:	e900                	sd	s0,16(a0)
    80002c50:	ed04                	sd	s1,24(a0)
    80002c52:	03253023          	sd	s2,32(a0)
    80002c56:	03353423          	sd	s3,40(a0)
    80002c5a:	03453823          	sd	s4,48(a0)
    80002c5e:	03553c23          	sd	s5,56(a0)
    80002c62:	05653023          	sd	s6,64(a0)
    80002c66:	05753423          	sd	s7,72(a0)
    80002c6a:	05853823          	sd	s8,80(a0)
    80002c6e:	05953c23          	sd	s9,88(a0)
    80002c72:	07a53023          	sd	s10,96(a0)
    80002c76:	07b53423          	sd	s11,104(a0)
    80002c7a:	0005b083          	ld	ra,0(a1)
    80002c7e:	0085b103          	ld	sp,8(a1)
    80002c82:	6980                	ld	s0,16(a1)
    80002c84:	6d84                	ld	s1,24(a1)
    80002c86:	0205b903          	ld	s2,32(a1)
    80002c8a:	0285b983          	ld	s3,40(a1)
    80002c8e:	0305ba03          	ld	s4,48(a1)
    80002c92:	0385ba83          	ld	s5,56(a1)
    80002c96:	0405bb03          	ld	s6,64(a1)
    80002c9a:	0485bb83          	ld	s7,72(a1)
    80002c9e:	0505bc03          	ld	s8,80(a1)
    80002ca2:	0585bc83          	ld	s9,88(a1)
    80002ca6:	0605bd03          	ld	s10,96(a1)
    80002caa:	0685bd83          	ld	s11,104(a1)
    80002cae:	8082                	ret

0000000080002cb0 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002cb0:	1141                	addi	sp,sp,-16
    80002cb2:	e406                	sd	ra,8(sp)
    80002cb4:	e022                	sd	s0,0(sp)
    80002cb6:	0800                	addi	s0,sp,16
    initlock(&tickslock, "time");
    80002cb8:	00005597          	auipc	a1,0x5
    80002cbc:	67858593          	addi	a1,a1,1656 # 80008330 <states.0+0x30>
    80002cc0:	00234517          	auipc	a0,0x234
    80002cc4:	72850513          	addi	a0,a0,1832 # 802373e8 <tickslock>
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	fae080e7          	jalr	-82(ra) # 80000c76 <initlock>
}
    80002cd0:	60a2                	ld	ra,8(sp)
    80002cd2:	6402                	ld	s0,0(sp)
    80002cd4:	0141                	addi	sp,sp,16
    80002cd6:	8082                	ret

0000000080002cd8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002cd8:	1141                	addi	sp,sp,-16
    80002cda:	e422                	sd	s0,8(sp)
    80002cdc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cde:	00003797          	auipc	a5,0x3
    80002ce2:	70278793          	addi	a5,a5,1794 # 800063e0 <kernelvec>
    80002ce6:	10579073          	csrw	stvec,a5
    w_stvec((uint64)kernelvec);
}
    80002cea:	6422                	ld	s0,8(sp)
    80002cec:	0141                	addi	sp,sp,16
    80002cee:	8082                	ret

0000000080002cf0 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002cf0:	1141                	addi	sp,sp,-16
    80002cf2:	e406                	sd	ra,8(sp)
    80002cf4:	e022                	sd	s0,0(sp)
    80002cf6:	0800                	addi	s0,sp,16
    struct proc *p = myproc();
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	eac080e7          	jalr	-340(ra) # 80001ba4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d00:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d04:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d06:	10079073          	csrw	sstatus,a5
    // kerneltrap() to usertrap(), so turn off interrupts until
    // we're back in user space, where usertrap() is correct.
    intr_off();

    // send syscalls, interrupts, and exceptions to uservec in trampoline.S
    uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d0a:	00004617          	auipc	a2,0x4
    80002d0e:	2f660613          	addi	a2,a2,758 # 80007000 <_trampoline>
    80002d12:	00004697          	auipc	a3,0x4
    80002d16:	2ee68693          	addi	a3,a3,750 # 80007000 <_trampoline>
    80002d1a:	8e91                	sub	a3,a3,a2
    80002d1c:	040007b7          	lui	a5,0x4000
    80002d20:	17fd                	addi	a5,a5,-1
    80002d22:	07b2                	slli	a5,a5,0xc
    80002d24:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d26:	10569073          	csrw	stvec,a3
    w_stvec(trampoline_uservec);

    // set up trapframe values that uservec will need when
    // the process next traps into the kernel.
    p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d2a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d2c:	180026f3          	csrr	a3,satp
    80002d30:	e314                	sd	a3,0(a4)
    p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d32:	6d38                	ld	a4,88(a0)
    80002d34:	6134                	ld	a3,64(a0)
    80002d36:	6585                	lui	a1,0x1
    80002d38:	96ae                	add	a3,a3,a1
    80002d3a:	e714                	sd	a3,8(a4)
    p->trapframe->kernel_trap = (uint64)usertrap;
    80002d3c:	6d38                	ld	a4,88(a0)
    80002d3e:	00000697          	auipc	a3,0x0
    80002d42:	13e68693          	addi	a3,a3,318 # 80002e7c <usertrap>
    80002d46:	eb14                	sd	a3,16(a4)
    p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002d48:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d4a:	8692                	mv	a3,tp
    80002d4c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4e:	100026f3          	csrr	a3,sstatus
    // set up the registers that trampoline.S's sret will use
    // to get to user space.

    // set S Previous Privilege mode to User.
    unsigned long x = r_sstatus();
    x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d52:	eff6f693          	andi	a3,a3,-257
    x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d56:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d5a:	10069073          	csrw	sstatus,a3
    w_sstatus(x);

    // set S Exception Program Counter to the saved user pc.
    w_sepc(p->trapframe->epc);
    80002d5e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d60:	6f18                	ld	a4,24(a4)
    80002d62:	14171073          	csrw	sepc,a4

    // tell trampoline.S the user page table to switch to.
    uint64 satp = MAKE_SATP(p->pagetable);
    80002d66:	6928                	ld	a0,80(a0)
    80002d68:	8131                	srli	a0,a0,0xc

    // jump to userret in trampoline.S at the top of memory, which
    // switches to the user page table, restores user registers,
    // and switches to user mode with sret.
    uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002d6a:	00004717          	auipc	a4,0x4
    80002d6e:	33270713          	addi	a4,a4,818 # 8000709c <userret>
    80002d72:	8f11                	sub	a4,a4,a2
    80002d74:	97ba                	add	a5,a5,a4
    ((void (*)(uint64))trampoline_userret)(satp);
    80002d76:	577d                	li	a4,-1
    80002d78:	177e                	slli	a4,a4,0x3f
    80002d7a:	8d59                	or	a0,a0,a4
    80002d7c:	9782                	jalr	a5
}
    80002d7e:	60a2                	ld	ra,8(sp)
    80002d80:	6402                	ld	s0,0(sp)
    80002d82:	0141                	addi	sp,sp,16
    80002d84:	8082                	ret

0000000080002d86 <clockintr>:
    w_sepc(sepc);
    w_sstatus(sstatus);
}

void clockintr()
{
    80002d86:	1101                	addi	sp,sp,-32
    80002d88:	ec06                	sd	ra,24(sp)
    80002d8a:	e822                	sd	s0,16(sp)
    80002d8c:	e426                	sd	s1,8(sp)
    80002d8e:	e04a                	sd	s2,0(sp)
    80002d90:	1000                	addi	s0,sp,32
    acquire(&tickslock);
    80002d92:	00234917          	auipc	s2,0x234
    80002d96:	65690913          	addi	s2,s2,1622 # 802373e8 <tickslock>
    80002d9a:	854a                	mv	a0,s2
    80002d9c:	ffffe097          	auipc	ra,0xffffe
    80002da0:	f6a080e7          	jalr	-150(ra) # 80000d06 <acquire>
    ticks++;
    80002da4:	00006497          	auipc	s1,0x6
    80002da8:	b8c48493          	addi	s1,s1,-1140 # 80008930 <ticks>
    80002dac:	409c                	lw	a5,0(s1)
    80002dae:	2785                	addiw	a5,a5,1
    80002db0:	c09c                	sw	a5,0(s1)
    update_time();
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	dc6080e7          	jalr	-570(ra) # 80002b78 <update_time>
    //   // {
    //   //   p->wtime++;
    //   // }
    //   release(&p->lock);
    // }
    wakeup(&ticks);
    80002dba:	8526                	mv	a0,s1
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	766080e7          	jalr	1894(ra) # 80002522 <wakeup>
    release(&tickslock);
    80002dc4:	854a                	mv	a0,s2
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	ff4080e7          	jalr	-12(ra) # 80000dba <release>
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	64a2                	ld	s1,8(sp)
    80002dd4:	6902                	ld	s2,0(sp)
    80002dd6:	6105                	addi	sp,sp,32
    80002dd8:	8082                	ret

0000000080002dda <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002de4:	14202773          	csrr	a4,scause
    uint64 scause = r_scause();

    if ((scause & 0x8000000000000000L) &&
    80002de8:	00074d63          	bltz	a4,80002e02 <devintr+0x28>
        if (irq)
            plic_complete(irq);

        return 1;
    }
    else if (scause == 0x8000000000000001L)
    80002dec:	57fd                	li	a5,-1
    80002dee:	17fe                	slli	a5,a5,0x3f
    80002df0:	0785                	addi	a5,a5,1

        return 2;
    }
    else
    {
        return 0;
    80002df2:	4501                	li	a0,0
    else if (scause == 0x8000000000000001L)
    80002df4:	06f70363          	beq	a4,a5,80002e5a <devintr+0x80>
    }
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6105                	addi	sp,sp,32
    80002e00:	8082                	ret
        (scause & 0xff) == 9)
    80002e02:	0ff77793          	andi	a5,a4,255
    if ((scause & 0x8000000000000000L) &&
    80002e06:	46a5                	li	a3,9
    80002e08:	fed792e3          	bne	a5,a3,80002dec <devintr+0x12>
        int irq = plic_claim();
    80002e0c:	00003097          	auipc	ra,0x3
    80002e10:	6dc080e7          	jalr	1756(ra) # 800064e8 <plic_claim>
    80002e14:	84aa                	mv	s1,a0
        if (irq == UART0_IRQ)
    80002e16:	47a9                	li	a5,10
    80002e18:	02f50763          	beq	a0,a5,80002e46 <devintr+0x6c>
        else if (irq == VIRTIO0_IRQ)
    80002e1c:	4785                	li	a5,1
    80002e1e:	02f50963          	beq	a0,a5,80002e50 <devintr+0x76>
        return 1;
    80002e22:	4505                	li	a0,1
        else if (irq)
    80002e24:	d8f1                	beqz	s1,80002df8 <devintr+0x1e>
            printf("unexpected interrupt irq=%d\n", irq);
    80002e26:	85a6                	mv	a1,s1
    80002e28:	00005517          	auipc	a0,0x5
    80002e2c:	51050513          	addi	a0,a0,1296 # 80008338 <states.0+0x38>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	758080e7          	jalr	1880(ra) # 80000588 <printf>
            plic_complete(irq);
    80002e38:	8526                	mv	a0,s1
    80002e3a:	00003097          	auipc	ra,0x3
    80002e3e:	6d2080e7          	jalr	1746(ra) # 8000650c <plic_complete>
        return 1;
    80002e42:	4505                	li	a0,1
    80002e44:	bf55                	j	80002df8 <devintr+0x1e>
            uartintr();
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	b54080e7          	jalr	-1196(ra) # 8000099a <uartintr>
    80002e4e:	b7ed                	j	80002e38 <devintr+0x5e>
            virtio_disk_intr();
    80002e50:	00004097          	auipc	ra,0x4
    80002e54:	b88080e7          	jalr	-1144(ra) # 800069d8 <virtio_disk_intr>
    80002e58:	b7c5                	j	80002e38 <devintr+0x5e>
        if (cpuid() == 0)
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	d1e080e7          	jalr	-738(ra) # 80001b78 <cpuid>
    80002e62:	c901                	beqz	a0,80002e72 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e64:	144027f3          	csrr	a5,sip
        w_sip(r_sip() & ~2);
    80002e68:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e6a:	14479073          	csrw	sip,a5
        return 2;
    80002e6e:	4509                	li	a0,2
    80002e70:	b761                	j	80002df8 <devintr+0x1e>
            clockintr();
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	f14080e7          	jalr	-236(ra) # 80002d86 <clockintr>
    80002e7a:	b7ed                	j	80002e64 <devintr+0x8a>

0000000080002e7c <usertrap>:
{
    80002e7c:	7139                	addi	sp,sp,-64
    80002e7e:	fc06                	sd	ra,56(sp)
    80002e80:	f822                	sd	s0,48(sp)
    80002e82:	f426                	sd	s1,40(sp)
    80002e84:	f04a                	sd	s2,32(sp)
    80002e86:	ec4e                	sd	s3,24(sp)
    80002e88:	e852                	sd	s4,16(sp)
    80002e8a:	e456                	sd	s5,8(sp)
    80002e8c:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e8e:	100027f3          	csrr	a5,sstatus
    if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002e92:	1007f793          	andi	a5,a5,256
    80002e96:	eff1                	bnez	a5,80002f72 <usertrap+0xf6>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e98:	00003797          	auipc	a5,0x3
    80002e9c:	54878793          	addi	a5,a5,1352 # 800063e0 <kernelvec>
    80002ea0:	10579073          	csrw	stvec,a5
    struct proc *p = myproc();
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	d00080e7          	jalr	-768(ra) # 80001ba4 <myproc>
    80002eac:	84aa                	mv	s1,a0
    p->trapframe->epc = r_sepc();
    80002eae:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb0:	14102773          	csrr	a4,sepc
    80002eb4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eb6:	14202773          	csrr	a4,scause
    if (r_scause() == 8)
    80002eba:	47a1                	li	a5,8
    80002ebc:	0cf70363          	beq	a4,a5,80002f82 <usertrap+0x106>
    else if ((which_dev = devintr()) != 0)
    80002ec0:	00000097          	auipc	ra,0x0
    80002ec4:	f1a080e7          	jalr	-230(ra) # 80002dda <devintr>
    80002ec8:	892a                	mv	s2,a0
    80002eca:	1a051d63          	bnez	a0,80003084 <usertrap+0x208>
    80002ece:	14202773          	csrr	a4,scause
    else if (r_scause() == 15)
    80002ed2:	47bd                	li	a5,15
    80002ed4:	16f71b63          	bne	a4,a5,8000304a <usertrap+0x1ce>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed8:	14302973          	csrr	s2,stval
        if (va_for_page_fault == 0)
    80002edc:	0e090f63          	beqz	s2,80002fda <usertrap+0x15e>
    80002ee0:	14302773          	csrr	a4,stval
        if (((uint64)r_stval()) >= MAXVA)
    80002ee4:	57fd                	li	a5,-1
    80002ee6:	83e9                	srli	a5,a5,0x1a
    80002ee8:	10e7e163          	bltu	a5,a4,80002fea <usertrap+0x16e>
        if ((va_for_page_fault <= PGROUNDDOWN(p->trapframe->sp) && va_for_page_fault >= PGROUNDDOWN(p->trapframe->sp) - PGSIZE))
    80002eec:	6cbc                	ld	a5,88(s1)
    80002eee:	7b98                	ld	a4,48(a5)
    80002ef0:	77fd                	lui	a5,0xfffff
    80002ef2:	8ff9                	and	a5,a5,a4
    80002ef4:	0127e663          	bltu	a5,s2,80002f00 <usertrap+0x84>
    80002ef8:	777d                	lui	a4,0xfffff
    80002efa:	97ba                	add	a5,a5,a4
    80002efc:	0ef97f63          	bgeu	s2,a5,80002ffa <usertrap+0x17e>
    80002f00:	143025f3          	csrr	a1,stval
        pte_t *page_table_entry = walk(p->pagetable, virtual_addr, 0);
    80002f04:	4601                	li	a2,0
    80002f06:	77fd                	lui	a5,0xfffff
    80002f08:	8dfd                	and	a1,a1,a5
    80002f0a:	68a8                	ld	a0,80(s1)
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	1da080e7          	jalr	474(ra) # 800010e6 <walk>
    80002f14:	89aa                	mv	s3,a0
        if (page_table_entry == 0)
    80002f16:	c975                	beqz	a0,8000300a <usertrap+0x18e>
        flags = PTE_FLAGS(*page_table_entry);
    80002f18:	0009b783          	ld	a5,0(s3)
        if ((flags & PTE_COW) == 0)
    80002f1c:	1007f793          	andi	a5,a5,256
    80002f20:	cfed                	beqz	a5,8000301a <usertrap+0x19e>
        uint64 physical_addr = PTE2PA(*page_table_entry);
    80002f22:	0009ba03          	ld	s4,0(s3)
    80002f26:	00aa5a13          	srli	s4,s4,0xa
    80002f2a:	0a32                	slli	s4,s4,0xc
        if (physical_addr == 0)
    80002f2c:	0e0a0f63          	beqz	s4,8000302a <usertrap+0x1ae>
        char *mem = (char *)kalloc();
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	ca8080e7          	jalr	-856(ra) # 80000bd8 <kalloc>
    80002f38:	892a                	mv	s2,a0
        if (mem == 0)
    80002f3a:	10050063          	beqz	a0,8000303a <usertrap+0x1be>
        flags = PTE_FLAGS(*page_table_entry);
    80002f3e:	0009ba83          	ld	s5,0(s3)
        flags = flags & (~PTE_COW);
    80002f42:	2ffafa93          	andi	s5,s5,767
        memmove(mem, (char *)physical_addr, PGSIZE);
    80002f46:	6605                	lui	a2,0x1
    80002f48:	85d2                	mv	a1,s4
    80002f4a:	854a                	mv	a0,s2
    80002f4c:	ffffe097          	auipc	ra,0xffffe
    80002f50:	f12080e7          	jalr	-238(ra) # 80000e5e <memmove>
        kfree((char *)physical_addr);
    80002f54:	8552                	mv	a0,s4
    80002f56:	ffffe097          	auipc	ra,0xffffe
    80002f5a:	a94080e7          	jalr	-1388(ra) # 800009ea <kfree>
        *page_table_entry = PA2PTE(mem) | flags;
    80002f5e:	00c95913          	srli	s2,s2,0xc
    80002f62:	092a                	slli	s2,s2,0xa
    80002f64:	004aea93          	ori	s5,s5,4
    80002f68:	01596933          	or	s2,s2,s5
    80002f6c:	0129b023          	sd	s2,0(s3)
    80002f70:	a825                	j	80002fa8 <usertrap+0x12c>
        panic("usertrap: not from user mode");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	3e650513          	addi	a0,a0,998 # 80008358 <states.0+0x58>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5c4080e7          	jalr	1476(ra) # 8000053e <panic>
        if (killed(p))
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	7f0080e7          	jalr	2032(ra) # 80002772 <killed>
    80002f8a:	e131                	bnez	a0,80002fce <usertrap+0x152>
        p->trapframe->epc += 4;
    80002f8c:	6cb8                	ld	a4,88(s1)
    80002f8e:	6f1c                	ld	a5,24(a4)
    80002f90:	0791                	addi	a5,a5,4
    80002f92:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f9c:	10079073          	csrw	sstatus,a5
        syscall();
    80002fa0:	00000097          	auipc	ra,0x0
    80002fa4:	358080e7          	jalr	856(ra) # 800032f8 <syscall>
    if (killed(p))
    80002fa8:	8526                	mv	a0,s1
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	7c8080e7          	jalr	1992(ra) # 80002772 <killed>
    80002fb2:	e165                	bnez	a0,80003092 <usertrap+0x216>
    usertrapret();
    80002fb4:	00000097          	auipc	ra,0x0
    80002fb8:	d3c080e7          	jalr	-708(ra) # 80002cf0 <usertrapret>
}
    80002fbc:	70e2                	ld	ra,56(sp)
    80002fbe:	7442                	ld	s0,48(sp)
    80002fc0:	74a2                	ld	s1,40(sp)
    80002fc2:	7902                	ld	s2,32(sp)
    80002fc4:	69e2                	ld	s3,24(sp)
    80002fc6:	6a42                	ld	s4,16(sp)
    80002fc8:	6aa2                	ld	s5,8(sp)
    80002fca:	6121                	addi	sp,sp,64
    80002fcc:	8082                	ret
            exit(-1);
    80002fce:	557d                	li	a0,-1
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	622080e7          	jalr	1570(ra) # 800025f2 <exit>
    80002fd8:	bf55                	j	80002f8c <usertrap+0x110>
            p->killed = 1;
    80002fda:	4785                	li	a5,1
    80002fdc:	d49c                	sw	a5,40(s1)
            exit(-1);
    80002fde:	557d                	li	a0,-1
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	612080e7          	jalr	1554(ra) # 800025f2 <exit>
    80002fe8:	bde5                	j	80002ee0 <usertrap+0x64>
            p->killed = 1;
    80002fea:	4785                	li	a5,1
    80002fec:	d49c                	sw	a5,40(s1)
            exit(-1);
    80002fee:	557d                	li	a0,-1
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	602080e7          	jalr	1538(ra) # 800025f2 <exit>
    80002ff8:	bdd5                	j	80002eec <usertrap+0x70>
            p->killed = 1;
    80002ffa:	4785                	li	a5,1
    80002ffc:	d49c                	sw	a5,40(s1)
            exit(-1);
    80002ffe:	557d                	li	a0,-1
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	5f2080e7          	jalr	1522(ra) # 800025f2 <exit>
    80003008:	bde5                	j	80002f00 <usertrap+0x84>
            p->killed = 1;
    8000300a:	4785                	li	a5,1
    8000300c:	d49c                	sw	a5,40(s1)
            exit(-1);
    8000300e:	557d                	li	a0,-1
    80003010:	fffff097          	auipc	ra,0xfffff
    80003014:	5e2080e7          	jalr	1506(ra) # 800025f2 <exit>
    80003018:	b701                	j	80002f18 <usertrap+0x9c>
            p->killed = 1;
    8000301a:	4785                	li	a5,1
    8000301c:	d49c                	sw	a5,40(s1)
            exit(-1);
    8000301e:	557d                	li	a0,-1
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	5d2080e7          	jalr	1490(ra) # 800025f2 <exit>
    80003028:	bded                	j	80002f22 <usertrap+0xa6>
            p->killed = 1;
    8000302a:	4785                	li	a5,1
    8000302c:	d49c                	sw	a5,40(s1)
            exit(-1);
    8000302e:	557d                	li	a0,-1
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	5c2080e7          	jalr	1474(ra) # 800025f2 <exit>
    80003038:	bde5                	j	80002f30 <usertrap+0xb4>
            p->killed = 1;
    8000303a:	4785                	li	a5,1
    8000303c:	d49c                	sw	a5,40(s1)
            exit(-1);
    8000303e:	557d                	li	a0,-1
    80003040:	fffff097          	auipc	ra,0xfffff
    80003044:	5b2080e7          	jalr	1458(ra) # 800025f2 <exit>
    80003048:	bddd                	j	80002f3e <usertrap+0xc2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000304a:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000304e:	5890                	lw	a2,48(s1)
    80003050:	00005517          	auipc	a0,0x5
    80003054:	32850513          	addi	a0,a0,808 # 80008378 <states.0+0x78>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	530080e7          	jalr	1328(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003060:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003064:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	34050513          	addi	a0,a0,832 # 800083a8 <states.0+0xa8>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	518080e7          	jalr	1304(ra) # 80000588 <printf>
        setkilled(p);
    80003078:	8526                	mv	a0,s1
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	6cc080e7          	jalr	1740(ra) # 80002746 <setkilled>
    80003082:	b71d                	j	80002fa8 <usertrap+0x12c>
    if (killed(p))
    80003084:	8526                	mv	a0,s1
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	6ec080e7          	jalr	1772(ra) # 80002772 <killed>
    8000308e:	c901                	beqz	a0,8000309e <usertrap+0x222>
    80003090:	a011                	j	80003094 <usertrap+0x218>
    80003092:	4901                	li	s2,0
        exit(-1);
    80003094:	557d                	li	a0,-1
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	55c080e7          	jalr	1372(ra) # 800025f2 <exit>
    if (which_dev == 2)
    8000309e:	4789                	li	a5,2
    800030a0:	f0f91ae3          	bne	s2,a5,80002fb4 <usertrap+0x138>
        yield();
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	2e4080e7          	jalr	740(ra) # 80002388 <yield>
    800030ac:	b721                	j	80002fb4 <usertrap+0x138>

00000000800030ae <kerneltrap>:
{
    800030ae:	7179                	addi	sp,sp,-48
    800030b0:	f406                	sd	ra,40(sp)
    800030b2:	f022                	sd	s0,32(sp)
    800030b4:	ec26                	sd	s1,24(sp)
    800030b6:	e84a                	sd	s2,16(sp)
    800030b8:	e44e                	sd	s3,8(sp)
    800030ba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030bc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030c4:	142029f3          	csrr	s3,scause
    if ((sstatus & SSTATUS_SPP) == 0)
    800030c8:	1004f793          	andi	a5,s1,256
    800030cc:	cb85                	beqz	a5,800030fc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030d2:	8b89                	andi	a5,a5,2
    if (intr_get() != 0)
    800030d4:	ef85                	bnez	a5,8000310c <kerneltrap+0x5e>
    if ((which_dev = devintr()) == 0)
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	d04080e7          	jalr	-764(ra) # 80002dda <devintr>
    800030de:	cd1d                	beqz	a0,8000311c <kerneltrap+0x6e>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030e0:	4789                	li	a5,2
    800030e2:	06f50a63          	beq	a0,a5,80003156 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030e6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030ea:	10049073          	csrw	sstatus,s1
}
    800030ee:	70a2                	ld	ra,40(sp)
    800030f0:	7402                	ld	s0,32(sp)
    800030f2:	64e2                	ld	s1,24(sp)
    800030f4:	6942                	ld	s2,16(sp)
    800030f6:	69a2                	ld	s3,8(sp)
    800030f8:	6145                	addi	sp,sp,48
    800030fa:	8082                	ret
        panic("kerneltrap: not from supervisor mode");
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	2cc50513          	addi	a0,a0,716 # 800083c8 <states.0+0xc8>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	43a080e7          	jalr	1082(ra) # 8000053e <panic>
        panic("kerneltrap: interrupts enabled");
    8000310c:	00005517          	auipc	a0,0x5
    80003110:	2e450513          	addi	a0,a0,740 # 800083f0 <states.0+0xf0>
    80003114:	ffffd097          	auipc	ra,0xffffd
    80003118:	42a080e7          	jalr	1066(ra) # 8000053e <panic>
        printf("scause %p\n", scause);
    8000311c:	85ce                	mv	a1,s3
    8000311e:	00005517          	auipc	a0,0x5
    80003122:	2f250513          	addi	a0,a0,754 # 80008410 <states.0+0x110>
    80003126:	ffffd097          	auipc	ra,0xffffd
    8000312a:	462080e7          	jalr	1122(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000312e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003132:	14302673          	csrr	a2,stval
        printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003136:	00005517          	auipc	a0,0x5
    8000313a:	2ea50513          	addi	a0,a0,746 # 80008420 <states.0+0x120>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	44a080e7          	jalr	1098(ra) # 80000588 <printf>
        panic("kerneltrap");
    80003146:	00005517          	auipc	a0,0x5
    8000314a:	2f250513          	addi	a0,a0,754 # 80008438 <states.0+0x138>
    8000314e:	ffffd097          	auipc	ra,0xffffd
    80003152:	3f0080e7          	jalr	1008(ra) # 8000053e <panic>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003156:	fffff097          	auipc	ra,0xfffff
    8000315a:	a4e080e7          	jalr	-1458(ra) # 80001ba4 <myproc>
    8000315e:	d541                	beqz	a0,800030e6 <kerneltrap+0x38>
    80003160:	fffff097          	auipc	ra,0xfffff
    80003164:	a44080e7          	jalr	-1468(ra) # 80001ba4 <myproc>
    80003168:	4d18                	lw	a4,24(a0)
    8000316a:	4791                	li	a5,4
    8000316c:	f6f71de3          	bne	a4,a5,800030e6 <kerneltrap+0x38>
        yield();
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	218080e7          	jalr	536(ra) # 80002388 <yield>
    80003178:	b7bd                	j	800030e6 <kerneltrap+0x38>

000000008000317a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000317a:	1101                	addi	sp,sp,-32
    8000317c:	ec06                	sd	ra,24(sp)
    8000317e:	e822                	sd	s0,16(sp)
    80003180:	e426                	sd	s1,8(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003186:	fffff097          	auipc	ra,0xfffff
    8000318a:	a1e080e7          	jalr	-1506(ra) # 80001ba4 <myproc>
  switch (n) {
    8000318e:	4795                	li	a5,5
    80003190:	0497e163          	bltu	a5,s1,800031d2 <argraw+0x58>
    80003194:	048a                	slli	s1,s1,0x2
    80003196:	00005717          	auipc	a4,0x5
    8000319a:	2da70713          	addi	a4,a4,730 # 80008470 <states.0+0x170>
    8000319e:	94ba                	add	s1,s1,a4
    800031a0:	409c                	lw	a5,0(s1)
    800031a2:	97ba                	add	a5,a5,a4
    800031a4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800031a6:	6d3c                	ld	a5,88(a0)
    800031a8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031aa:	60e2                	ld	ra,24(sp)
    800031ac:	6442                	ld	s0,16(sp)
    800031ae:	64a2                	ld	s1,8(sp)
    800031b0:	6105                	addi	sp,sp,32
    800031b2:	8082                	ret
    return p->trapframe->a1;
    800031b4:	6d3c                	ld	a5,88(a0)
    800031b6:	7fa8                	ld	a0,120(a5)
    800031b8:	bfcd                	j	800031aa <argraw+0x30>
    return p->trapframe->a2;
    800031ba:	6d3c                	ld	a5,88(a0)
    800031bc:	63c8                	ld	a0,128(a5)
    800031be:	b7f5                	j	800031aa <argraw+0x30>
    return p->trapframe->a3;
    800031c0:	6d3c                	ld	a5,88(a0)
    800031c2:	67c8                	ld	a0,136(a5)
    800031c4:	b7dd                	j	800031aa <argraw+0x30>
    return p->trapframe->a4;
    800031c6:	6d3c                	ld	a5,88(a0)
    800031c8:	6bc8                	ld	a0,144(a5)
    800031ca:	b7c5                	j	800031aa <argraw+0x30>
    return p->trapframe->a5;
    800031cc:	6d3c                	ld	a5,88(a0)
    800031ce:	6fc8                	ld	a0,152(a5)
    800031d0:	bfe9                	j	800031aa <argraw+0x30>
  panic("argraw");
    800031d2:	00005517          	auipc	a0,0x5
    800031d6:	27650513          	addi	a0,a0,630 # 80008448 <states.0+0x148>
    800031da:	ffffd097          	auipc	ra,0xffffd
    800031de:	364080e7          	jalr	868(ra) # 8000053e <panic>

00000000800031e2 <fetchaddr>:
{
    800031e2:	1101                	addi	sp,sp,-32
    800031e4:	ec06                	sd	ra,24(sp)
    800031e6:	e822                	sd	s0,16(sp)
    800031e8:	e426                	sd	s1,8(sp)
    800031ea:	e04a                	sd	s2,0(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84aa                	mv	s1,a0
    800031f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031f2:	fffff097          	auipc	ra,0xfffff
    800031f6:	9b2080e7          	jalr	-1614(ra) # 80001ba4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800031fa:	653c                	ld	a5,72(a0)
    800031fc:	02f4f863          	bgeu	s1,a5,8000322c <fetchaddr+0x4a>
    80003200:	00848713          	addi	a4,s1,8
    80003204:	02e7e663          	bltu	a5,a4,80003230 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003208:	46a1                	li	a3,8
    8000320a:	8626                	mv	a2,s1
    8000320c:	85ca                	mv	a1,s2
    8000320e:	6928                	ld	a0,80(a0)
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	6dc080e7          	jalr	1756(ra) # 800018ec <copyin>
    80003218:	00a03533          	snez	a0,a0
    8000321c:	40a00533          	neg	a0,a0
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    return -1;
    8000322c:	557d                	li	a0,-1
    8000322e:	bfcd                	j	80003220 <fetchaddr+0x3e>
    80003230:	557d                	li	a0,-1
    80003232:	b7fd                	j	80003220 <fetchaddr+0x3e>

0000000080003234 <fetchstr>:
{
    80003234:	7179                	addi	sp,sp,-48
    80003236:	f406                	sd	ra,40(sp)
    80003238:	f022                	sd	s0,32(sp)
    8000323a:	ec26                	sd	s1,24(sp)
    8000323c:	e84a                	sd	s2,16(sp)
    8000323e:	e44e                	sd	s3,8(sp)
    80003240:	1800                	addi	s0,sp,48
    80003242:	892a                	mv	s2,a0
    80003244:	84ae                	mv	s1,a1
    80003246:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003248:	fffff097          	auipc	ra,0xfffff
    8000324c:	95c080e7          	jalr	-1700(ra) # 80001ba4 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003250:	86ce                	mv	a3,s3
    80003252:	864a                	mv	a2,s2
    80003254:	85a6                	mv	a1,s1
    80003256:	6928                	ld	a0,80(a0)
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	722080e7          	jalr	1826(ra) # 8000197a <copyinstr>
    80003260:	00054e63          	bltz	a0,8000327c <fetchstr+0x48>
  return strlen(buf);
    80003264:	8526                	mv	a0,s1
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	d18080e7          	jalr	-744(ra) # 80000f7e <strlen>
}
    8000326e:	70a2                	ld	ra,40(sp)
    80003270:	7402                	ld	s0,32(sp)
    80003272:	64e2                	ld	s1,24(sp)
    80003274:	6942                	ld	s2,16(sp)
    80003276:	69a2                	ld	s3,8(sp)
    80003278:	6145                	addi	sp,sp,48
    8000327a:	8082                	ret
    return -1;
    8000327c:	557d                	li	a0,-1
    8000327e:	bfc5                	j	8000326e <fetchstr+0x3a>

0000000080003280 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003280:	1101                	addi	sp,sp,-32
    80003282:	ec06                	sd	ra,24(sp)
    80003284:	e822                	sd	s0,16(sp)
    80003286:	e426                	sd	s1,8(sp)
    80003288:	1000                	addi	s0,sp,32
    8000328a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000328c:	00000097          	auipc	ra,0x0
    80003290:	eee080e7          	jalr	-274(ra) # 8000317a <argraw>
    80003294:	c088                	sw	a0,0(s1)
}
    80003296:	60e2                	ld	ra,24(sp)
    80003298:	6442                	ld	s0,16(sp)
    8000329a:	64a2                	ld	s1,8(sp)
    8000329c:	6105                	addi	sp,sp,32
    8000329e:	8082                	ret

00000000800032a0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800032a0:	1101                	addi	sp,sp,-32
    800032a2:	ec06                	sd	ra,24(sp)
    800032a4:	e822                	sd	s0,16(sp)
    800032a6:	e426                	sd	s1,8(sp)
    800032a8:	1000                	addi	s0,sp,32
    800032aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	ece080e7          	jalr	-306(ra) # 8000317a <argraw>
    800032b4:	e088                	sd	a0,0(s1)
}
    800032b6:	60e2                	ld	ra,24(sp)
    800032b8:	6442                	ld	s0,16(sp)
    800032ba:	64a2                	ld	s1,8(sp)
    800032bc:	6105                	addi	sp,sp,32
    800032be:	8082                	ret

00000000800032c0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032c0:	7179                	addi	sp,sp,-48
    800032c2:	f406                	sd	ra,40(sp)
    800032c4:	f022                	sd	s0,32(sp)
    800032c6:	ec26                	sd	s1,24(sp)
    800032c8:	e84a                	sd	s2,16(sp)
    800032ca:	1800                	addi	s0,sp,48
    800032cc:	84ae                	mv	s1,a1
    800032ce:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800032d0:	fd840593          	addi	a1,s0,-40
    800032d4:	00000097          	auipc	ra,0x0
    800032d8:	fcc080e7          	jalr	-52(ra) # 800032a0 <argaddr>
  return fetchstr(addr, buf, max);
    800032dc:	864a                	mv	a2,s2
    800032de:	85a6                	mv	a1,s1
    800032e0:	fd843503          	ld	a0,-40(s0)
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	f50080e7          	jalr	-176(ra) # 80003234 <fetchstr>
}
    800032ec:	70a2                	ld	ra,40(sp)
    800032ee:	7402                	ld	s0,32(sp)
    800032f0:	64e2                	ld	s1,24(sp)
    800032f2:	6942                	ld	s2,16(sp)
    800032f4:	6145                	addi	sp,sp,48
    800032f6:	8082                	ret

00000000800032f8 <syscall>:
[SYS_set_priority] sys_set_priority,
};

void
syscall(void)
{
    800032f8:	1101                	addi	sp,sp,-32
    800032fa:	ec06                	sd	ra,24(sp)
    800032fc:	e822                	sd	s0,16(sp)
    800032fe:	e426                	sd	s1,8(sp)
    80003300:	e04a                	sd	s2,0(sp)
    80003302:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003304:	fffff097          	auipc	ra,0xfffff
    80003308:	8a0080e7          	jalr	-1888(ra) # 80001ba4 <myproc>
    8000330c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000330e:	05853903          	ld	s2,88(a0)
    80003312:	0a893783          	ld	a5,168(s2)
    80003316:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000331a:	37fd                	addiw	a5,a5,-1
    8000331c:	475d                	li	a4,23
    8000331e:	00f76f63          	bltu	a4,a5,8000333c <syscall+0x44>
    80003322:	00369713          	slli	a4,a3,0x3
    80003326:	00005797          	auipc	a5,0x5
    8000332a:	16278793          	addi	a5,a5,354 # 80008488 <syscalls>
    8000332e:	97ba                	add	a5,a5,a4
    80003330:	639c                	ld	a5,0(a5)
    80003332:	c789                	beqz	a5,8000333c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003334:	9782                	jalr	a5
    80003336:	06a93823          	sd	a0,112(s2)
    8000333a:	a839                	j	80003358 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000333c:	15848613          	addi	a2,s1,344
    80003340:	588c                	lw	a1,48(s1)
    80003342:	00005517          	auipc	a0,0x5
    80003346:	10e50513          	addi	a0,a0,270 # 80008450 <states.0+0x150>
    8000334a:	ffffd097          	auipc	ra,0xffffd
    8000334e:	23e080e7          	jalr	574(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003352:	6cbc                	ld	a5,88(s1)
    80003354:	577d                	li	a4,-1
    80003356:	fbb8                	sd	a4,112(a5)
  }
}
    80003358:	60e2                	ld	ra,24(sp)
    8000335a:	6442                	ld	s0,16(sp)
    8000335c:	64a2                	ld	s1,8(sp)
    8000335e:	6902                	ld	s2,0(sp)
    80003360:	6105                	addi	sp,sp,32
    80003362:	8082                	ret

0000000080003364 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003364:	1101                	addi	sp,sp,-32
    80003366:	ec06                	sd	ra,24(sp)
    80003368:	e822                	sd	s0,16(sp)
    8000336a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000336c:	fec40593          	addi	a1,s0,-20
    80003370:	4501                	li	a0,0
    80003372:	00000097          	auipc	ra,0x0
    80003376:	f0e080e7          	jalr	-242(ra) # 80003280 <argint>
  exit(n);
    8000337a:	fec42503          	lw	a0,-20(s0)
    8000337e:	fffff097          	auipc	ra,0xfffff
    80003382:	274080e7          	jalr	628(ra) # 800025f2 <exit>
  return 0; // not reached
}
    80003386:	4501                	li	a0,0
    80003388:	60e2                	ld	ra,24(sp)
    8000338a:	6442                	ld	s0,16(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret

0000000080003390 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003390:	1141                	addi	sp,sp,-16
    80003392:	e406                	sd	ra,8(sp)
    80003394:	e022                	sd	s0,0(sp)
    80003396:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003398:	fffff097          	auipc	ra,0xfffff
    8000339c:	80c080e7          	jalr	-2036(ra) # 80001ba4 <myproc>
}
    800033a0:	5908                	lw	a0,48(a0)
    800033a2:	60a2                	ld	ra,8(sp)
    800033a4:	6402                	ld	s0,0(sp)
    800033a6:	0141                	addi	sp,sp,16
    800033a8:	8082                	ret

00000000800033aa <sys_fork>:

uint64
sys_fork(void)
{
    800033aa:	1141                	addi	sp,sp,-16
    800033ac:	e406                	sd	ra,8(sp)
    800033ae:	e022                	sd	s0,0(sp)
    800033b0:	0800                	addi	s0,sp,16
  return fork();
    800033b2:	fffff097          	auipc	ra,0xfffff
    800033b6:	be2080e7          	jalr	-1054(ra) # 80001f94 <fork>
}
    800033ba:	60a2                	ld	ra,8(sp)
    800033bc:	6402                	ld	s0,0(sp)
    800033be:	0141                	addi	sp,sp,16
    800033c0:	8082                	ret

00000000800033c2 <sys_wait>:

uint64
sys_wait(void)
{
    800033c2:	1101                	addi	sp,sp,-32
    800033c4:	ec06                	sd	ra,24(sp)
    800033c6:	e822                	sd	s0,16(sp)
    800033c8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800033ca:	fe840593          	addi	a1,s0,-24
    800033ce:	4501                	li	a0,0
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	ed0080e7          	jalr	-304(ra) # 800032a0 <argaddr>
  return wait(p);
    800033d8:	fe843503          	ld	a0,-24(s0)
    800033dc:	fffff097          	auipc	ra,0xfffff
    800033e0:	3c8080e7          	jalr	968(ra) # 800027a4 <wait>
}
    800033e4:	60e2                	ld	ra,24(sp)
    800033e6:	6442                	ld	s0,16(sp)
    800033e8:	6105                	addi	sp,sp,32
    800033ea:	8082                	ret

00000000800033ec <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033ec:	7179                	addi	sp,sp,-48
    800033ee:	f406                	sd	ra,40(sp)
    800033f0:	f022                	sd	s0,32(sp)
    800033f2:	ec26                	sd	s1,24(sp)
    800033f4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800033f6:	fdc40593          	addi	a1,s0,-36
    800033fa:	4501                	li	a0,0
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	e84080e7          	jalr	-380(ra) # 80003280 <argint>
  addr = myproc()->sz;
    80003404:	ffffe097          	auipc	ra,0xffffe
    80003408:	7a0080e7          	jalr	1952(ra) # 80001ba4 <myproc>
    8000340c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000340e:	fdc42503          	lw	a0,-36(s0)
    80003412:	fffff097          	auipc	ra,0xfffff
    80003416:	b26080e7          	jalr	-1242(ra) # 80001f38 <growproc>
    8000341a:	00054863          	bltz	a0,8000342a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000341e:	8526                	mv	a0,s1
    80003420:	70a2                	ld	ra,40(sp)
    80003422:	7402                	ld	s0,32(sp)
    80003424:	64e2                	ld	s1,24(sp)
    80003426:	6145                	addi	sp,sp,48
    80003428:	8082                	ret
    return -1;
    8000342a:	54fd                	li	s1,-1
    8000342c:	bfcd                	j	8000341e <sys_sbrk+0x32>

000000008000342e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000342e:	7139                	addi	sp,sp,-64
    80003430:	fc06                	sd	ra,56(sp)
    80003432:	f822                	sd	s0,48(sp)
    80003434:	f426                	sd	s1,40(sp)
    80003436:	f04a                	sd	s2,32(sp)
    80003438:	ec4e                	sd	s3,24(sp)
    8000343a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    8000343c:	fcc40593          	addi	a1,s0,-52
    80003440:	4501                	li	a0,0
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e3e080e7          	jalr	-450(ra) # 80003280 <argint>
  acquire(&tickslock);
    8000344a:	00234517          	auipc	a0,0x234
    8000344e:	f9e50513          	addi	a0,a0,-98 # 802373e8 <tickslock>
    80003452:	ffffe097          	auipc	ra,0xffffe
    80003456:	8b4080e7          	jalr	-1868(ra) # 80000d06 <acquire>
  ticks0 = ticks;
    8000345a:	00005917          	auipc	s2,0x5
    8000345e:	4d692903          	lw	s2,1238(s2) # 80008930 <ticks>
  while (ticks - ticks0 < n)
    80003462:	fcc42783          	lw	a5,-52(s0)
    80003466:	cf9d                	beqz	a5,800034a4 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003468:	00234997          	auipc	s3,0x234
    8000346c:	f8098993          	addi	s3,s3,-128 # 802373e8 <tickslock>
    80003470:	00005497          	auipc	s1,0x5
    80003474:	4c048493          	addi	s1,s1,1216 # 80008930 <ticks>
    if (killed(myproc()))
    80003478:	ffffe097          	auipc	ra,0xffffe
    8000347c:	72c080e7          	jalr	1836(ra) # 80001ba4 <myproc>
    80003480:	fffff097          	auipc	ra,0xfffff
    80003484:	2f2080e7          	jalr	754(ra) # 80002772 <killed>
    80003488:	ed15                	bnez	a0,800034c4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000348a:	85ce                	mv	a1,s3
    8000348c:	8526                	mv	a0,s1
    8000348e:	fffff097          	auipc	ra,0xfffff
    80003492:	030080e7          	jalr	48(ra) # 800024be <sleep>
  while (ticks - ticks0 < n)
    80003496:	409c                	lw	a5,0(s1)
    80003498:	412787bb          	subw	a5,a5,s2
    8000349c:	fcc42703          	lw	a4,-52(s0)
    800034a0:	fce7ece3          	bltu	a5,a4,80003478 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800034a4:	00234517          	auipc	a0,0x234
    800034a8:	f4450513          	addi	a0,a0,-188 # 802373e8 <tickslock>
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	90e080e7          	jalr	-1778(ra) # 80000dba <release>
  return 0;
    800034b4:	4501                	li	a0,0
}
    800034b6:	70e2                	ld	ra,56(sp)
    800034b8:	7442                	ld	s0,48(sp)
    800034ba:	74a2                	ld	s1,40(sp)
    800034bc:	7902                	ld	s2,32(sp)
    800034be:	69e2                	ld	s3,24(sp)
    800034c0:	6121                	addi	sp,sp,64
    800034c2:	8082                	ret
      release(&tickslock);
    800034c4:	00234517          	auipc	a0,0x234
    800034c8:	f2450513          	addi	a0,a0,-220 # 802373e8 <tickslock>
    800034cc:	ffffe097          	auipc	ra,0xffffe
    800034d0:	8ee080e7          	jalr	-1810(ra) # 80000dba <release>
      return -1;
    800034d4:	557d                	li	a0,-1
    800034d6:	b7c5                	j	800034b6 <sys_sleep+0x88>

00000000800034d8 <sys_kill>:

uint64
sys_kill(void)
{
    800034d8:	1101                	addi	sp,sp,-32
    800034da:	ec06                	sd	ra,24(sp)
    800034dc:	e822                	sd	s0,16(sp)
    800034de:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800034e0:	fec40593          	addi	a1,s0,-20
    800034e4:	4501                	li	a0,0
    800034e6:	00000097          	auipc	ra,0x0
    800034ea:	d9a080e7          	jalr	-614(ra) # 80003280 <argint>
  return kill(pid);
    800034ee:	fec42503          	lw	a0,-20(s0)
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	1e2080e7          	jalr	482(ra) # 800026d4 <kill>
}
    800034fa:	60e2                	ld	ra,24(sp)
    800034fc:	6442                	ld	s0,16(sp)
    800034fe:	6105                	addi	sp,sp,32
    80003500:	8082                	ret

0000000080003502 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003502:	1101                	addi	sp,sp,-32
    80003504:	ec06                	sd	ra,24(sp)
    80003506:	e822                	sd	s0,16(sp)
    80003508:	e426                	sd	s1,8(sp)
    8000350a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000350c:	00234517          	auipc	a0,0x234
    80003510:	edc50513          	addi	a0,a0,-292 # 802373e8 <tickslock>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	7f2080e7          	jalr	2034(ra) # 80000d06 <acquire>
  xticks = ticks;
    8000351c:	00005497          	auipc	s1,0x5
    80003520:	4144a483          	lw	s1,1044(s1) # 80008930 <ticks>
  release(&tickslock);
    80003524:	00234517          	auipc	a0,0x234
    80003528:	ec450513          	addi	a0,a0,-316 # 802373e8 <tickslock>
    8000352c:	ffffe097          	auipc	ra,0xffffe
    80003530:	88e080e7          	jalr	-1906(ra) # 80000dba <release>
  return xticks;
}
    80003534:	02049513          	slli	a0,s1,0x20
    80003538:	9101                	srli	a0,a0,0x20
    8000353a:	60e2                	ld	ra,24(sp)
    8000353c:	6442                	ld	s0,16(sp)
    8000353e:	64a2                	ld	s1,8(sp)
    80003540:	6105                	addi	sp,sp,32
    80003542:	8082                	ret

0000000080003544 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003544:	7139                	addi	sp,sp,-64
    80003546:	fc06                	sd	ra,56(sp)
    80003548:	f822                	sd	s0,48(sp)
    8000354a:	f426                	sd	s1,40(sp)
    8000354c:	f04a                	sd	s2,32(sp)
    8000354e:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003550:	fd840593          	addi	a1,s0,-40
    80003554:	4501                	li	a0,0
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	d4a080e7          	jalr	-694(ra) # 800032a0 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000355e:	fd040593          	addi	a1,s0,-48
    80003562:	4505                	li	a0,1
    80003564:	00000097          	auipc	ra,0x0
    80003568:	d3c080e7          	jalr	-708(ra) # 800032a0 <argaddr>
  argaddr(2, &addr2);
    8000356c:	fc840593          	addi	a1,s0,-56
    80003570:	4509                	li	a0,2
    80003572:	00000097          	auipc	ra,0x0
    80003576:	d2e080e7          	jalr	-722(ra) # 800032a0 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000357a:	fc040613          	addi	a2,s0,-64
    8000357e:	fc440593          	addi	a1,s0,-60
    80003582:	fd843503          	ld	a0,-40(s0)
    80003586:	fffff097          	auipc	ra,0xfffff
    8000358a:	4a6080e7          	jalr	1190(ra) # 80002a2c <waitx>
    8000358e:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003590:	ffffe097          	auipc	ra,0xffffe
    80003594:	614080e7          	jalr	1556(ra) # 80001ba4 <myproc>
    80003598:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    8000359a:	4691                	li	a3,4
    8000359c:	fc440613          	addi	a2,s0,-60
    800035a0:	fd043583          	ld	a1,-48(s0)
    800035a4:	6928                	ld	a0,80(a0)
    800035a6:	ffffe097          	auipc	ra,0xffffe
    800035aa:	238080e7          	jalr	568(ra) # 800017de <copyout>
    return -1;
    800035ae:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800035b0:	00054f63          	bltz	a0,800035ce <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800035b4:	4691                	li	a3,4
    800035b6:	fc040613          	addi	a2,s0,-64
    800035ba:	fc843583          	ld	a1,-56(s0)
    800035be:	68a8                	ld	a0,80(s1)
    800035c0:	ffffe097          	auipc	ra,0xffffe
    800035c4:	21e080e7          	jalr	542(ra) # 800017de <copyout>
    800035c8:	00054a63          	bltz	a0,800035dc <sys_waitx+0x98>
    return -1;
  return ret;
    800035cc:	87ca                	mv	a5,s2
}
    800035ce:	853e                	mv	a0,a5
    800035d0:	70e2                	ld	ra,56(sp)
    800035d2:	7442                	ld	s0,48(sp)
    800035d4:	74a2                	ld	s1,40(sp)
    800035d6:	7902                	ld	s2,32(sp)
    800035d8:	6121                	addi	sp,sp,64
    800035da:	8082                	ret
    return -1;
    800035dc:	57fd                	li	a5,-1
    800035de:	bfc5                	j	800035ce <sys_waitx+0x8a>

00000000800035e0 <sys_set_priority>:
uint64 sys_set_priority(void)
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	1000                	addi	s0,sp,32
    int priority, pid;
    argint(0, &pid);
    800035e8:	fe840593          	addi	a1,s0,-24
    800035ec:	4501                	li	a0,0
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	c92080e7          	jalr	-878(ra) # 80003280 <argint>
    argint(1, &priority);
    800035f6:	fec40593          	addi	a1,s0,-20
    800035fa:	4505                	li	a0,1
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	c84080e7          	jalr	-892(ra) # 80003280 <argint>
    if (priority < 0 || priority > 100)
    80003604:	fec42583          	lw	a1,-20(s0)
    80003608:	0005871b          	sext.w	a4,a1
    8000360c:	06400793          	li	a5,100
    80003610:	00e7ec63          	bltu	a5,a4,80003628 <sys_set_priority+0x48>
    {
        printf("Invalid priority\n");
        return -1;
    }
    int res = setPriority(pid, priority);
    80003614:	fe842503          	lw	a0,-24(s0)
    80003618:	fffff097          	auipc	ra,0xfffff
    8000361c:	dac080e7          	jalr	-596(ra) # 800023c4 <setPriority>
    {
        return res;
    }
    // printf("pRIORITY sET\n");
    return res;
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	6105                	addi	sp,sp,32
    80003626:	8082                	ret
        printf("Invalid priority\n");
    80003628:	00005517          	auipc	a0,0x5
    8000362c:	f2850513          	addi	a0,a0,-216 # 80008550 <syscalls+0xc8>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	f58080e7          	jalr	-168(ra) # 80000588 <printf>
        return -1;
    80003638:	557d                	li	a0,-1
    8000363a:	b7dd                	j	80003620 <sys_set_priority+0x40>

000000008000363c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000363c:	7179                	addi	sp,sp,-48
    8000363e:	f406                	sd	ra,40(sp)
    80003640:	f022                	sd	s0,32(sp)
    80003642:	ec26                	sd	s1,24(sp)
    80003644:	e84a                	sd	s2,16(sp)
    80003646:	e44e                	sd	s3,8(sp)
    80003648:	e052                	sd	s4,0(sp)
    8000364a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000364c:	00005597          	auipc	a1,0x5
    80003650:	f1c58593          	addi	a1,a1,-228 # 80008568 <syscalls+0xe0>
    80003654:	00234517          	auipc	a0,0x234
    80003658:	dac50513          	addi	a0,a0,-596 # 80237400 <bcache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	61a080e7          	jalr	1562(ra) # 80000c76 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003664:	0023c797          	auipc	a5,0x23c
    80003668:	d9c78793          	addi	a5,a5,-612 # 8023f400 <bcache+0x8000>
    8000366c:	0023c717          	auipc	a4,0x23c
    80003670:	ffc70713          	addi	a4,a4,-4 # 8023f668 <bcache+0x8268>
    80003674:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003678:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000367c:	00234497          	auipc	s1,0x234
    80003680:	d9c48493          	addi	s1,s1,-612 # 80237418 <bcache+0x18>
    b->next = bcache.head.next;
    80003684:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003686:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003688:	00005a17          	auipc	s4,0x5
    8000368c:	ee8a0a13          	addi	s4,s4,-280 # 80008570 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003690:	2b893783          	ld	a5,696(s2)
    80003694:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003696:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000369a:	85d2                	mv	a1,s4
    8000369c:	01048513          	addi	a0,s1,16
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	4c4080e7          	jalr	1220(ra) # 80004b64 <initsleeplock>
    bcache.head.next->prev = b;
    800036a8:	2b893783          	ld	a5,696(s2)
    800036ac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036ae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036b2:	45848493          	addi	s1,s1,1112
    800036b6:	fd349de3          	bne	s1,s3,80003690 <binit+0x54>
  }
}
    800036ba:	70a2                	ld	ra,40(sp)
    800036bc:	7402                	ld	s0,32(sp)
    800036be:	64e2                	ld	s1,24(sp)
    800036c0:	6942                	ld	s2,16(sp)
    800036c2:	69a2                	ld	s3,8(sp)
    800036c4:	6a02                	ld	s4,0(sp)
    800036c6:	6145                	addi	sp,sp,48
    800036c8:	8082                	ret

00000000800036ca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036ca:	7179                	addi	sp,sp,-48
    800036cc:	f406                	sd	ra,40(sp)
    800036ce:	f022                	sd	s0,32(sp)
    800036d0:	ec26                	sd	s1,24(sp)
    800036d2:	e84a                	sd	s2,16(sp)
    800036d4:	e44e                	sd	s3,8(sp)
    800036d6:	1800                	addi	s0,sp,48
    800036d8:	892a                	mv	s2,a0
    800036da:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036dc:	00234517          	auipc	a0,0x234
    800036e0:	d2450513          	addi	a0,a0,-732 # 80237400 <bcache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	622080e7          	jalr	1570(ra) # 80000d06 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036ec:	0023c497          	auipc	s1,0x23c
    800036f0:	fcc4b483          	ld	s1,-52(s1) # 8023f6b8 <bcache+0x82b8>
    800036f4:	0023c797          	auipc	a5,0x23c
    800036f8:	f7478793          	addi	a5,a5,-140 # 8023f668 <bcache+0x8268>
    800036fc:	02f48f63          	beq	s1,a5,8000373a <bread+0x70>
    80003700:	873e                	mv	a4,a5
    80003702:	a021                	j	8000370a <bread+0x40>
    80003704:	68a4                	ld	s1,80(s1)
    80003706:	02e48a63          	beq	s1,a4,8000373a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000370a:	449c                	lw	a5,8(s1)
    8000370c:	ff279ce3          	bne	a5,s2,80003704 <bread+0x3a>
    80003710:	44dc                	lw	a5,12(s1)
    80003712:	ff3799e3          	bne	a5,s3,80003704 <bread+0x3a>
      b->refcnt++;
    80003716:	40bc                	lw	a5,64(s1)
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000371c:	00234517          	auipc	a0,0x234
    80003720:	ce450513          	addi	a0,a0,-796 # 80237400 <bcache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	696080e7          	jalr	1686(ra) # 80000dba <release>
      acquiresleep(&b->lock);
    8000372c:	01048513          	addi	a0,s1,16
    80003730:	00001097          	auipc	ra,0x1
    80003734:	46e080e7          	jalr	1134(ra) # 80004b9e <acquiresleep>
      return b;
    80003738:	a8b9                	j	80003796 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000373a:	0023c497          	auipc	s1,0x23c
    8000373e:	f764b483          	ld	s1,-138(s1) # 8023f6b0 <bcache+0x82b0>
    80003742:	0023c797          	auipc	a5,0x23c
    80003746:	f2678793          	addi	a5,a5,-218 # 8023f668 <bcache+0x8268>
    8000374a:	00f48863          	beq	s1,a5,8000375a <bread+0x90>
    8000374e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003750:	40bc                	lw	a5,64(s1)
    80003752:	cf81                	beqz	a5,8000376a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003754:	64a4                	ld	s1,72(s1)
    80003756:	fee49de3          	bne	s1,a4,80003750 <bread+0x86>
  panic("bget: no buffers");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	e1e50513          	addi	a0,a0,-482 # 80008578 <syscalls+0xf0>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	ddc080e7          	jalr	-548(ra) # 8000053e <panic>
      b->dev = dev;
    8000376a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000376e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003772:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003776:	4785                	li	a5,1
    80003778:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000377a:	00234517          	auipc	a0,0x234
    8000377e:	c8650513          	addi	a0,a0,-890 # 80237400 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	638080e7          	jalr	1592(ra) # 80000dba <release>
      acquiresleep(&b->lock);
    8000378a:	01048513          	addi	a0,s1,16
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	410080e7          	jalr	1040(ra) # 80004b9e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003796:	409c                	lw	a5,0(s1)
    80003798:	cb89                	beqz	a5,800037aa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000379a:	8526                	mv	a0,s1
    8000379c:	70a2                	ld	ra,40(sp)
    8000379e:	7402                	ld	s0,32(sp)
    800037a0:	64e2                	ld	s1,24(sp)
    800037a2:	6942                	ld	s2,16(sp)
    800037a4:	69a2                	ld	s3,8(sp)
    800037a6:	6145                	addi	sp,sp,48
    800037a8:	8082                	ret
    virtio_disk_rw(b, 0);
    800037aa:	4581                	li	a1,0
    800037ac:	8526                	mv	a0,s1
    800037ae:	00003097          	auipc	ra,0x3
    800037b2:	ff6080e7          	jalr	-10(ra) # 800067a4 <virtio_disk_rw>
    b->valid = 1;
    800037b6:	4785                	li	a5,1
    800037b8:	c09c                	sw	a5,0(s1)
  return b;
    800037ba:	b7c5                	j	8000379a <bread+0xd0>

00000000800037bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037c8:	0541                	addi	a0,a0,16
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	46e080e7          	jalr	1134(ra) # 80004c38 <holdingsleep>
    800037d2:	cd01                	beqz	a0,800037ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037d4:	4585                	li	a1,1
    800037d6:	8526                	mv	a0,s1
    800037d8:	00003097          	auipc	ra,0x3
    800037dc:	fcc080e7          	jalr	-52(ra) # 800067a4 <virtio_disk_rw>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret
    panic("bwrite");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	da650513          	addi	a0,a0,-602 # 80008590 <syscalls+0x108>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d4c080e7          	jalr	-692(ra) # 8000053e <panic>

00000000800037fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
    80003806:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003808:	01050913          	addi	s2,a0,16
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	42a080e7          	jalr	1066(ra) # 80004c38 <holdingsleep>
    80003816:	c92d                	beqz	a0,80003888 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003818:	854a                	mv	a0,s2
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	3da080e7          	jalr	986(ra) # 80004bf4 <releasesleep>

  acquire(&bcache.lock);
    80003822:	00234517          	auipc	a0,0x234
    80003826:	bde50513          	addi	a0,a0,-1058 # 80237400 <bcache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	4dc080e7          	jalr	1244(ra) # 80000d06 <acquire>
  b->refcnt--;
    80003832:	40bc                	lw	a5,64(s1)
    80003834:	37fd                	addiw	a5,a5,-1
    80003836:	0007871b          	sext.w	a4,a5
    8000383a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000383c:	eb05                	bnez	a4,8000386c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000383e:	68bc                	ld	a5,80(s1)
    80003840:	64b8                	ld	a4,72(s1)
    80003842:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003844:	64bc                	ld	a5,72(s1)
    80003846:	68b8                	ld	a4,80(s1)
    80003848:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000384a:	0023c797          	auipc	a5,0x23c
    8000384e:	bb678793          	addi	a5,a5,-1098 # 8023f400 <bcache+0x8000>
    80003852:	2b87b703          	ld	a4,696(a5)
    80003856:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003858:	0023c717          	auipc	a4,0x23c
    8000385c:	e1070713          	addi	a4,a4,-496 # 8023f668 <bcache+0x8268>
    80003860:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003862:	2b87b703          	ld	a4,696(a5)
    80003866:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003868:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000386c:	00234517          	auipc	a0,0x234
    80003870:	b9450513          	addi	a0,a0,-1132 # 80237400 <bcache>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	546080e7          	jalr	1350(ra) # 80000dba <release>
}
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6902                	ld	s2,0(sp)
    80003884:	6105                	addi	sp,sp,32
    80003886:	8082                	ret
    panic("brelse");
    80003888:	00005517          	auipc	a0,0x5
    8000388c:	d1050513          	addi	a0,a0,-752 # 80008598 <syscalls+0x110>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	cae080e7          	jalr	-850(ra) # 8000053e <panic>

0000000080003898 <bpin>:

void
bpin(struct buf *b) {
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038a4:	00234517          	auipc	a0,0x234
    800038a8:	b5c50513          	addi	a0,a0,-1188 # 80237400 <bcache>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	45a080e7          	jalr	1114(ra) # 80000d06 <acquire>
  b->refcnt++;
    800038b4:	40bc                	lw	a5,64(s1)
    800038b6:	2785                	addiw	a5,a5,1
    800038b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ba:	00234517          	auipc	a0,0x234
    800038be:	b4650513          	addi	a0,a0,-1210 # 80237400 <bcache>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	4f8080e7          	jalr	1272(ra) # 80000dba <release>
}
    800038ca:	60e2                	ld	ra,24(sp)
    800038cc:	6442                	ld	s0,16(sp)
    800038ce:	64a2                	ld	s1,8(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <bunpin>:

void
bunpin(struct buf *b) {
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	e426                	sd	s1,8(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038e0:	00234517          	auipc	a0,0x234
    800038e4:	b2050513          	addi	a0,a0,-1248 # 80237400 <bcache>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	41e080e7          	jalr	1054(ra) # 80000d06 <acquire>
  b->refcnt--;
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	37fd                	addiw	a5,a5,-1
    800038f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038f6:	00234517          	auipc	a0,0x234
    800038fa:	b0a50513          	addi	a0,a0,-1270 # 80237400 <bcache>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	4bc080e7          	jalr	1212(ra) # 80000dba <release>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6105                	addi	sp,sp,32
    8000390e:	8082                	ret

0000000080003910 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003910:	1101                	addi	sp,sp,-32
    80003912:	ec06                	sd	ra,24(sp)
    80003914:	e822                	sd	s0,16(sp)
    80003916:	e426                	sd	s1,8(sp)
    80003918:	e04a                	sd	s2,0(sp)
    8000391a:	1000                	addi	s0,sp,32
    8000391c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000391e:	00d5d59b          	srliw	a1,a1,0xd
    80003922:	0023c797          	auipc	a5,0x23c
    80003926:	1ba7a783          	lw	a5,442(a5) # 8023fadc <sb+0x1c>
    8000392a:	9dbd                	addw	a1,a1,a5
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	d9e080e7          	jalr	-610(ra) # 800036ca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003934:	0074f713          	andi	a4,s1,7
    80003938:	4785                	li	a5,1
    8000393a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000393e:	14ce                	slli	s1,s1,0x33
    80003940:	90d9                	srli	s1,s1,0x36
    80003942:	00950733          	add	a4,a0,s1
    80003946:	05874703          	lbu	a4,88(a4)
    8000394a:	00e7f6b3          	and	a3,a5,a4
    8000394e:	c69d                	beqz	a3,8000397c <bfree+0x6c>
    80003950:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003952:	94aa                	add	s1,s1,a0
    80003954:	fff7c793          	not	a5,a5
    80003958:	8ff9                	and	a5,a5,a4
    8000395a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	120080e7          	jalr	288(ra) # 80004a7e <log_write>
  brelse(bp);
    80003966:	854a                	mv	a0,s2
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	e92080e7          	jalr	-366(ra) # 800037fa <brelse>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6902                	ld	s2,0(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret
    panic("freeing free block");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	c2450513          	addi	a0,a0,-988 # 800085a0 <syscalls+0x118>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	bba080e7          	jalr	-1094(ra) # 8000053e <panic>

000000008000398c <balloc>:
{
    8000398c:	711d                	addi	sp,sp,-96
    8000398e:	ec86                	sd	ra,88(sp)
    80003990:	e8a2                	sd	s0,80(sp)
    80003992:	e4a6                	sd	s1,72(sp)
    80003994:	e0ca                	sd	s2,64(sp)
    80003996:	fc4e                	sd	s3,56(sp)
    80003998:	f852                	sd	s4,48(sp)
    8000399a:	f456                	sd	s5,40(sp)
    8000399c:	f05a                	sd	s6,32(sp)
    8000399e:	ec5e                	sd	s7,24(sp)
    800039a0:	e862                	sd	s8,16(sp)
    800039a2:	e466                	sd	s9,8(sp)
    800039a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039a6:	0023c797          	auipc	a5,0x23c
    800039aa:	11e7a783          	lw	a5,286(a5) # 8023fac4 <sb+0x4>
    800039ae:	10078163          	beqz	a5,80003ab0 <balloc+0x124>
    800039b2:	8baa                	mv	s7,a0
    800039b4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039b6:	0023cb17          	auipc	s6,0x23c
    800039ba:	10ab0b13          	addi	s6,s6,266 # 8023fac0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039be:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039c0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039c4:	6c89                	lui	s9,0x2
    800039c6:	a061                	j	80003a4e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039c8:	974a                	add	a4,a4,s2
    800039ca:	8fd5                	or	a5,a5,a3
    800039cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	0ac080e7          	jalr	172(ra) # 80004a7e <log_write>
        brelse(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	e1e080e7          	jalr	-482(ra) # 800037fa <brelse>
  bp = bread(dev, bno);
    800039e4:	85a6                	mv	a1,s1
    800039e6:	855e                	mv	a0,s7
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	ce2080e7          	jalr	-798(ra) # 800036ca <bread>
    800039f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039f2:	40000613          	li	a2,1024
    800039f6:	4581                	li	a1,0
    800039f8:	05850513          	addi	a0,a0,88
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	406080e7          	jalr	1030(ra) # 80000e02 <memset>
  log_write(bp);
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	078080e7          	jalr	120(ra) # 80004a7e <log_write>
  brelse(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	dea080e7          	jalr	-534(ra) # 800037fa <brelse>
}
    80003a18:	8526                	mv	a0,s1
    80003a1a:	60e6                	ld	ra,88(sp)
    80003a1c:	6446                	ld	s0,80(sp)
    80003a1e:	64a6                	ld	s1,72(sp)
    80003a20:	6906                	ld	s2,64(sp)
    80003a22:	79e2                	ld	s3,56(sp)
    80003a24:	7a42                	ld	s4,48(sp)
    80003a26:	7aa2                	ld	s5,40(sp)
    80003a28:	7b02                	ld	s6,32(sp)
    80003a2a:	6be2                	ld	s7,24(sp)
    80003a2c:	6c42                	ld	s8,16(sp)
    80003a2e:	6ca2                	ld	s9,8(sp)
    80003a30:	6125                	addi	sp,sp,96
    80003a32:	8082                	ret
    brelse(bp);
    80003a34:	854a                	mv	a0,s2
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	dc4080e7          	jalr	-572(ra) # 800037fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003a3e:	015c87bb          	addw	a5,s9,s5
    80003a42:	00078a9b          	sext.w	s5,a5
    80003a46:	004b2703          	lw	a4,4(s6)
    80003a4a:	06eaf363          	bgeu	s5,a4,80003ab0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003a4e:	41fad79b          	sraiw	a5,s5,0x1f
    80003a52:	0137d79b          	srliw	a5,a5,0x13
    80003a56:	015787bb          	addw	a5,a5,s5
    80003a5a:	40d7d79b          	sraiw	a5,a5,0xd
    80003a5e:	01cb2583          	lw	a1,28(s6)
    80003a62:	9dbd                	addw	a1,a1,a5
    80003a64:	855e                	mv	a0,s7
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	c64080e7          	jalr	-924(ra) # 800036ca <bread>
    80003a6e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a70:	004b2503          	lw	a0,4(s6)
    80003a74:	000a849b          	sext.w	s1,s5
    80003a78:	8662                	mv	a2,s8
    80003a7a:	faa4fde3          	bgeu	s1,a0,80003a34 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003a7e:	41f6579b          	sraiw	a5,a2,0x1f
    80003a82:	01d7d69b          	srliw	a3,a5,0x1d
    80003a86:	00c6873b          	addw	a4,a3,a2
    80003a8a:	00777793          	andi	a5,a4,7
    80003a8e:	9f95                	subw	a5,a5,a3
    80003a90:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a94:	4037571b          	sraiw	a4,a4,0x3
    80003a98:	00e906b3          	add	a3,s2,a4
    80003a9c:	0586c683          	lbu	a3,88(a3)
    80003aa0:	00d7f5b3          	and	a1,a5,a3
    80003aa4:	d195                	beqz	a1,800039c8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aa6:	2605                	addiw	a2,a2,1
    80003aa8:	2485                	addiw	s1,s1,1
    80003aaa:	fd4618e3          	bne	a2,s4,80003a7a <balloc+0xee>
    80003aae:	b759                	j	80003a34 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003ab0:	00005517          	auipc	a0,0x5
    80003ab4:	b0850513          	addi	a0,a0,-1272 # 800085b8 <syscalls+0x130>
    80003ab8:	ffffd097          	auipc	ra,0xffffd
    80003abc:	ad0080e7          	jalr	-1328(ra) # 80000588 <printf>
  return 0;
    80003ac0:	4481                	li	s1,0
    80003ac2:	bf99                	j	80003a18 <balloc+0x8c>

0000000080003ac4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ac4:	7179                	addi	sp,sp,-48
    80003ac6:	f406                	sd	ra,40(sp)
    80003ac8:	f022                	sd	s0,32(sp)
    80003aca:	ec26                	sd	s1,24(sp)
    80003acc:	e84a                	sd	s2,16(sp)
    80003ace:	e44e                	sd	s3,8(sp)
    80003ad0:	e052                	sd	s4,0(sp)
    80003ad2:	1800                	addi	s0,sp,48
    80003ad4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ad6:	47ad                	li	a5,11
    80003ad8:	02b7e763          	bltu	a5,a1,80003b06 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003adc:	02059493          	slli	s1,a1,0x20
    80003ae0:	9081                	srli	s1,s1,0x20
    80003ae2:	048a                	slli	s1,s1,0x2
    80003ae4:	94aa                	add	s1,s1,a0
    80003ae6:	0504a903          	lw	s2,80(s1)
    80003aea:	06091e63          	bnez	s2,80003b66 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003aee:	4108                	lw	a0,0(a0)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	e9c080e7          	jalr	-356(ra) # 8000398c <balloc>
    80003af8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003afc:	06090563          	beqz	s2,80003b66 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003b00:	0524a823          	sw	s2,80(s1)
    80003b04:	a08d                	j	80003b66 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003b06:	ff45849b          	addiw	s1,a1,-12
    80003b0a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003b0e:	0ff00793          	li	a5,255
    80003b12:	08e7e563          	bltu	a5,a4,80003b9c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003b16:	08052903          	lw	s2,128(a0)
    80003b1a:	00091d63          	bnez	s2,80003b34 <bmap+0x70>
      addr = balloc(ip->dev);
    80003b1e:	4108                	lw	a0,0(a0)
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	e6c080e7          	jalr	-404(ra) # 8000398c <balloc>
    80003b28:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003b2c:	02090d63          	beqz	s2,80003b66 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003b30:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003b34:	85ca                	mv	a1,s2
    80003b36:	0009a503          	lw	a0,0(s3)
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	b90080e7          	jalr	-1136(ra) # 800036ca <bread>
    80003b42:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003b44:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003b48:	02049593          	slli	a1,s1,0x20
    80003b4c:	9181                	srli	a1,a1,0x20
    80003b4e:	058a                	slli	a1,a1,0x2
    80003b50:	00b784b3          	add	s1,a5,a1
    80003b54:	0004a903          	lw	s2,0(s1)
    80003b58:	02090063          	beqz	s2,80003b78 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003b5c:	8552                	mv	a0,s4
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	c9c080e7          	jalr	-868(ra) # 800037fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b66:	854a                	mv	a0,s2
    80003b68:	70a2                	ld	ra,40(sp)
    80003b6a:	7402                	ld	s0,32(sp)
    80003b6c:	64e2                	ld	s1,24(sp)
    80003b6e:	6942                	ld	s2,16(sp)
    80003b70:	69a2                	ld	s3,8(sp)
    80003b72:	6a02                	ld	s4,0(sp)
    80003b74:	6145                	addi	sp,sp,48
    80003b76:	8082                	ret
      addr = balloc(ip->dev);
    80003b78:	0009a503          	lw	a0,0(s3)
    80003b7c:	00000097          	auipc	ra,0x0
    80003b80:	e10080e7          	jalr	-496(ra) # 8000398c <balloc>
    80003b84:	0005091b          	sext.w	s2,a0
      if(addr){
    80003b88:	fc090ae3          	beqz	s2,80003b5c <bmap+0x98>
        a[bn] = addr;
    80003b8c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003b90:	8552                	mv	a0,s4
    80003b92:	00001097          	auipc	ra,0x1
    80003b96:	eec080e7          	jalr	-276(ra) # 80004a7e <log_write>
    80003b9a:	b7c9                	j	80003b5c <bmap+0x98>
  panic("bmap: out of range");
    80003b9c:	00005517          	auipc	a0,0x5
    80003ba0:	a3450513          	addi	a0,a0,-1484 # 800085d0 <syscalls+0x148>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	99a080e7          	jalr	-1638(ra) # 8000053e <panic>

0000000080003bac <iget>:
{
    80003bac:	7179                	addi	sp,sp,-48
    80003bae:	f406                	sd	ra,40(sp)
    80003bb0:	f022                	sd	s0,32(sp)
    80003bb2:	ec26                	sd	s1,24(sp)
    80003bb4:	e84a                	sd	s2,16(sp)
    80003bb6:	e44e                	sd	s3,8(sp)
    80003bb8:	e052                	sd	s4,0(sp)
    80003bba:	1800                	addi	s0,sp,48
    80003bbc:	89aa                	mv	s3,a0
    80003bbe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bc0:	0023c517          	auipc	a0,0x23c
    80003bc4:	f2050513          	addi	a0,a0,-224 # 8023fae0 <itable>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	13e080e7          	jalr	318(ra) # 80000d06 <acquire>
  empty = 0;
    80003bd0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bd2:	0023c497          	auipc	s1,0x23c
    80003bd6:	f2648493          	addi	s1,s1,-218 # 8023faf8 <itable+0x18>
    80003bda:	0023e697          	auipc	a3,0x23e
    80003bde:	9ae68693          	addi	a3,a3,-1618 # 80241588 <log>
    80003be2:	a039                	j	80003bf0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003be4:	02090b63          	beqz	s2,80003c1a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003be8:	08848493          	addi	s1,s1,136
    80003bec:	02d48a63          	beq	s1,a3,80003c20 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bf0:	449c                	lw	a5,8(s1)
    80003bf2:	fef059e3          	blez	a5,80003be4 <iget+0x38>
    80003bf6:	4098                	lw	a4,0(s1)
    80003bf8:	ff3716e3          	bne	a4,s3,80003be4 <iget+0x38>
    80003bfc:	40d8                	lw	a4,4(s1)
    80003bfe:	ff4713e3          	bne	a4,s4,80003be4 <iget+0x38>
      ip->ref++;
    80003c02:	2785                	addiw	a5,a5,1
    80003c04:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003c06:	0023c517          	auipc	a0,0x23c
    80003c0a:	eda50513          	addi	a0,a0,-294 # 8023fae0 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	1ac080e7          	jalr	428(ra) # 80000dba <release>
      return ip;
    80003c16:	8926                	mv	s2,s1
    80003c18:	a03d                	j	80003c46 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c1a:	f7f9                	bnez	a5,80003be8 <iget+0x3c>
    80003c1c:	8926                	mv	s2,s1
    80003c1e:	b7e9                	j	80003be8 <iget+0x3c>
  if(empty == 0)
    80003c20:	02090c63          	beqz	s2,80003c58 <iget+0xac>
  ip->dev = dev;
    80003c24:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c28:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c2c:	4785                	li	a5,1
    80003c2e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c32:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c36:	0023c517          	auipc	a0,0x23c
    80003c3a:	eaa50513          	addi	a0,a0,-342 # 8023fae0 <itable>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	17c080e7          	jalr	380(ra) # 80000dba <release>
}
    80003c46:	854a                	mv	a0,s2
    80003c48:	70a2                	ld	ra,40(sp)
    80003c4a:	7402                	ld	s0,32(sp)
    80003c4c:	64e2                	ld	s1,24(sp)
    80003c4e:	6942                	ld	s2,16(sp)
    80003c50:	69a2                	ld	s3,8(sp)
    80003c52:	6a02                	ld	s4,0(sp)
    80003c54:	6145                	addi	sp,sp,48
    80003c56:	8082                	ret
    panic("iget: no inodes");
    80003c58:	00005517          	auipc	a0,0x5
    80003c5c:	99050513          	addi	a0,a0,-1648 # 800085e8 <syscalls+0x160>
    80003c60:	ffffd097          	auipc	ra,0xffffd
    80003c64:	8de080e7          	jalr	-1826(ra) # 8000053e <panic>

0000000080003c68 <fsinit>:
fsinit(int dev) {
    80003c68:	7179                	addi	sp,sp,-48
    80003c6a:	f406                	sd	ra,40(sp)
    80003c6c:	f022                	sd	s0,32(sp)
    80003c6e:	ec26                	sd	s1,24(sp)
    80003c70:	e84a                	sd	s2,16(sp)
    80003c72:	e44e                	sd	s3,8(sp)
    80003c74:	1800                	addi	s0,sp,48
    80003c76:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c78:	4585                	li	a1,1
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	a50080e7          	jalr	-1456(ra) # 800036ca <bread>
    80003c82:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c84:	0023c997          	auipc	s3,0x23c
    80003c88:	e3c98993          	addi	s3,s3,-452 # 8023fac0 <sb>
    80003c8c:	02000613          	li	a2,32
    80003c90:	05850593          	addi	a1,a0,88
    80003c94:	854e                	mv	a0,s3
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	1c8080e7          	jalr	456(ra) # 80000e5e <memmove>
  brelse(bp);
    80003c9e:	8526                	mv	a0,s1
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	b5a080e7          	jalr	-1190(ra) # 800037fa <brelse>
  if(sb.magic != FSMAGIC)
    80003ca8:	0009a703          	lw	a4,0(s3)
    80003cac:	102037b7          	lui	a5,0x10203
    80003cb0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003cb4:	02f71263          	bne	a4,a5,80003cd8 <fsinit+0x70>
  initlog(dev, &sb);
    80003cb8:	0023c597          	auipc	a1,0x23c
    80003cbc:	e0858593          	addi	a1,a1,-504 # 8023fac0 <sb>
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00001097          	auipc	ra,0x1
    80003cc6:	b40080e7          	jalr	-1216(ra) # 80004802 <initlog>
}
    80003cca:	70a2                	ld	ra,40(sp)
    80003ccc:	7402                	ld	s0,32(sp)
    80003cce:	64e2                	ld	s1,24(sp)
    80003cd0:	6942                	ld	s2,16(sp)
    80003cd2:	69a2                	ld	s3,8(sp)
    80003cd4:	6145                	addi	sp,sp,48
    80003cd6:	8082                	ret
    panic("invalid file system");
    80003cd8:	00005517          	auipc	a0,0x5
    80003cdc:	92050513          	addi	a0,a0,-1760 # 800085f8 <syscalls+0x170>
    80003ce0:	ffffd097          	auipc	ra,0xffffd
    80003ce4:	85e080e7          	jalr	-1954(ra) # 8000053e <panic>

0000000080003ce8 <iinit>:
{
    80003ce8:	7179                	addi	sp,sp,-48
    80003cea:	f406                	sd	ra,40(sp)
    80003cec:	f022                	sd	s0,32(sp)
    80003cee:	ec26                	sd	s1,24(sp)
    80003cf0:	e84a                	sd	s2,16(sp)
    80003cf2:	e44e                	sd	s3,8(sp)
    80003cf4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003cf6:	00005597          	auipc	a1,0x5
    80003cfa:	91a58593          	addi	a1,a1,-1766 # 80008610 <syscalls+0x188>
    80003cfe:	0023c517          	auipc	a0,0x23c
    80003d02:	de250513          	addi	a0,a0,-542 # 8023fae0 <itable>
    80003d06:	ffffd097          	auipc	ra,0xffffd
    80003d0a:	f70080e7          	jalr	-144(ra) # 80000c76 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003d0e:	0023c497          	auipc	s1,0x23c
    80003d12:	dfa48493          	addi	s1,s1,-518 # 8023fb08 <itable+0x28>
    80003d16:	0023e997          	auipc	s3,0x23e
    80003d1a:	88298993          	addi	s3,s3,-1918 # 80241598 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d1e:	00005917          	auipc	s2,0x5
    80003d22:	8fa90913          	addi	s2,s2,-1798 # 80008618 <syscalls+0x190>
    80003d26:	85ca                	mv	a1,s2
    80003d28:	8526                	mv	a0,s1
    80003d2a:	00001097          	auipc	ra,0x1
    80003d2e:	e3a080e7          	jalr	-454(ra) # 80004b64 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d32:	08848493          	addi	s1,s1,136
    80003d36:	ff3498e3          	bne	s1,s3,80003d26 <iinit+0x3e>
}
    80003d3a:	70a2                	ld	ra,40(sp)
    80003d3c:	7402                	ld	s0,32(sp)
    80003d3e:	64e2                	ld	s1,24(sp)
    80003d40:	6942                	ld	s2,16(sp)
    80003d42:	69a2                	ld	s3,8(sp)
    80003d44:	6145                	addi	sp,sp,48
    80003d46:	8082                	ret

0000000080003d48 <ialloc>:
{
    80003d48:	715d                	addi	sp,sp,-80
    80003d4a:	e486                	sd	ra,72(sp)
    80003d4c:	e0a2                	sd	s0,64(sp)
    80003d4e:	fc26                	sd	s1,56(sp)
    80003d50:	f84a                	sd	s2,48(sp)
    80003d52:	f44e                	sd	s3,40(sp)
    80003d54:	f052                	sd	s4,32(sp)
    80003d56:	ec56                	sd	s5,24(sp)
    80003d58:	e85a                	sd	s6,16(sp)
    80003d5a:	e45e                	sd	s7,8(sp)
    80003d5c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d5e:	0023c717          	auipc	a4,0x23c
    80003d62:	d6e72703          	lw	a4,-658(a4) # 8023facc <sb+0xc>
    80003d66:	4785                	li	a5,1
    80003d68:	04e7fa63          	bgeu	a5,a4,80003dbc <ialloc+0x74>
    80003d6c:	8aaa                	mv	s5,a0
    80003d6e:	8bae                	mv	s7,a1
    80003d70:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d72:	0023ca17          	auipc	s4,0x23c
    80003d76:	d4ea0a13          	addi	s4,s4,-690 # 8023fac0 <sb>
    80003d7a:	00048b1b          	sext.w	s6,s1
    80003d7e:	0044d793          	srli	a5,s1,0x4
    80003d82:	018a2583          	lw	a1,24(s4)
    80003d86:	9dbd                	addw	a1,a1,a5
    80003d88:	8556                	mv	a0,s5
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	940080e7          	jalr	-1728(ra) # 800036ca <bread>
    80003d92:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d94:	05850993          	addi	s3,a0,88
    80003d98:	00f4f793          	andi	a5,s1,15
    80003d9c:	079a                	slli	a5,a5,0x6
    80003d9e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003da0:	00099783          	lh	a5,0(s3)
    80003da4:	c3a1                	beqz	a5,80003de4 <ialloc+0x9c>
    brelse(bp);
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	a54080e7          	jalr	-1452(ra) # 800037fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003dae:	0485                	addi	s1,s1,1
    80003db0:	00ca2703          	lw	a4,12(s4)
    80003db4:	0004879b          	sext.w	a5,s1
    80003db8:	fce7e1e3          	bltu	a5,a4,80003d7a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003dbc:	00005517          	auipc	a0,0x5
    80003dc0:	86450513          	addi	a0,a0,-1948 # 80008620 <syscalls+0x198>
    80003dc4:	ffffc097          	auipc	ra,0xffffc
    80003dc8:	7c4080e7          	jalr	1988(ra) # 80000588 <printf>
  return 0;
    80003dcc:	4501                	li	a0,0
}
    80003dce:	60a6                	ld	ra,72(sp)
    80003dd0:	6406                	ld	s0,64(sp)
    80003dd2:	74e2                	ld	s1,56(sp)
    80003dd4:	7942                	ld	s2,48(sp)
    80003dd6:	79a2                	ld	s3,40(sp)
    80003dd8:	7a02                	ld	s4,32(sp)
    80003dda:	6ae2                	ld	s5,24(sp)
    80003ddc:	6b42                	ld	s6,16(sp)
    80003dde:	6ba2                	ld	s7,8(sp)
    80003de0:	6161                	addi	sp,sp,80
    80003de2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003de4:	04000613          	li	a2,64
    80003de8:	4581                	li	a1,0
    80003dea:	854e                	mv	a0,s3
    80003dec:	ffffd097          	auipc	ra,0xffffd
    80003df0:	016080e7          	jalr	22(ra) # 80000e02 <memset>
      dip->type = type;
    80003df4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003df8:	854a                	mv	a0,s2
    80003dfa:	00001097          	auipc	ra,0x1
    80003dfe:	c84080e7          	jalr	-892(ra) # 80004a7e <log_write>
      brelse(bp);
    80003e02:	854a                	mv	a0,s2
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	9f6080e7          	jalr	-1546(ra) # 800037fa <brelse>
      return iget(dev, inum);
    80003e0c:	85da                	mv	a1,s6
    80003e0e:	8556                	mv	a0,s5
    80003e10:	00000097          	auipc	ra,0x0
    80003e14:	d9c080e7          	jalr	-612(ra) # 80003bac <iget>
    80003e18:	bf5d                	j	80003dce <ialloc+0x86>

0000000080003e1a <iupdate>:
{
    80003e1a:	1101                	addi	sp,sp,-32
    80003e1c:	ec06                	sd	ra,24(sp)
    80003e1e:	e822                	sd	s0,16(sp)
    80003e20:	e426                	sd	s1,8(sp)
    80003e22:	e04a                	sd	s2,0(sp)
    80003e24:	1000                	addi	s0,sp,32
    80003e26:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e28:	415c                	lw	a5,4(a0)
    80003e2a:	0047d79b          	srliw	a5,a5,0x4
    80003e2e:	0023c597          	auipc	a1,0x23c
    80003e32:	caa5a583          	lw	a1,-854(a1) # 8023fad8 <sb+0x18>
    80003e36:	9dbd                	addw	a1,a1,a5
    80003e38:	4108                	lw	a0,0(a0)
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	890080e7          	jalr	-1904(ra) # 800036ca <bread>
    80003e42:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e44:	05850793          	addi	a5,a0,88
    80003e48:	40c8                	lw	a0,4(s1)
    80003e4a:	893d                	andi	a0,a0,15
    80003e4c:	051a                	slli	a0,a0,0x6
    80003e4e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e50:	04449703          	lh	a4,68(s1)
    80003e54:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e58:	04649703          	lh	a4,70(s1)
    80003e5c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e60:	04849703          	lh	a4,72(s1)
    80003e64:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e68:	04a49703          	lh	a4,74(s1)
    80003e6c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e70:	44f8                	lw	a4,76(s1)
    80003e72:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e74:	03400613          	li	a2,52
    80003e78:	05048593          	addi	a1,s1,80
    80003e7c:	0531                	addi	a0,a0,12
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	fe0080e7          	jalr	-32(ra) # 80000e5e <memmove>
  log_write(bp);
    80003e86:	854a                	mv	a0,s2
    80003e88:	00001097          	auipc	ra,0x1
    80003e8c:	bf6080e7          	jalr	-1034(ra) # 80004a7e <log_write>
  brelse(bp);
    80003e90:	854a                	mv	a0,s2
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	968080e7          	jalr	-1688(ra) # 800037fa <brelse>
}
    80003e9a:	60e2                	ld	ra,24(sp)
    80003e9c:	6442                	ld	s0,16(sp)
    80003e9e:	64a2                	ld	s1,8(sp)
    80003ea0:	6902                	ld	s2,0(sp)
    80003ea2:	6105                	addi	sp,sp,32
    80003ea4:	8082                	ret

0000000080003ea6 <idup>:
{
    80003ea6:	1101                	addi	sp,sp,-32
    80003ea8:	ec06                	sd	ra,24(sp)
    80003eaa:	e822                	sd	s0,16(sp)
    80003eac:	e426                	sd	s1,8(sp)
    80003eae:	1000                	addi	s0,sp,32
    80003eb0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb2:	0023c517          	auipc	a0,0x23c
    80003eb6:	c2e50513          	addi	a0,a0,-978 # 8023fae0 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	e4c080e7          	jalr	-436(ra) # 80000d06 <acquire>
  ip->ref++;
    80003ec2:	449c                	lw	a5,8(s1)
    80003ec4:	2785                	addiw	a5,a5,1
    80003ec6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ec8:	0023c517          	auipc	a0,0x23c
    80003ecc:	c1850513          	addi	a0,a0,-1000 # 8023fae0 <itable>
    80003ed0:	ffffd097          	auipc	ra,0xffffd
    80003ed4:	eea080e7          	jalr	-278(ra) # 80000dba <release>
}
    80003ed8:	8526                	mv	a0,s1
    80003eda:	60e2                	ld	ra,24(sp)
    80003edc:	6442                	ld	s0,16(sp)
    80003ede:	64a2                	ld	s1,8(sp)
    80003ee0:	6105                	addi	sp,sp,32
    80003ee2:	8082                	ret

0000000080003ee4 <ilock>:
{
    80003ee4:	1101                	addi	sp,sp,-32
    80003ee6:	ec06                	sd	ra,24(sp)
    80003ee8:	e822                	sd	s0,16(sp)
    80003eea:	e426                	sd	s1,8(sp)
    80003eec:	e04a                	sd	s2,0(sp)
    80003eee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ef0:	c115                	beqz	a0,80003f14 <ilock+0x30>
    80003ef2:	84aa                	mv	s1,a0
    80003ef4:	451c                	lw	a5,8(a0)
    80003ef6:	00f05f63          	blez	a5,80003f14 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003efa:	0541                	addi	a0,a0,16
    80003efc:	00001097          	auipc	ra,0x1
    80003f00:	ca2080e7          	jalr	-862(ra) # 80004b9e <acquiresleep>
  if(ip->valid == 0){
    80003f04:	40bc                	lw	a5,64(s1)
    80003f06:	cf99                	beqz	a5,80003f24 <ilock+0x40>
}
    80003f08:	60e2                	ld	ra,24(sp)
    80003f0a:	6442                	ld	s0,16(sp)
    80003f0c:	64a2                	ld	s1,8(sp)
    80003f0e:	6902                	ld	s2,0(sp)
    80003f10:	6105                	addi	sp,sp,32
    80003f12:	8082                	ret
    panic("ilock");
    80003f14:	00004517          	auipc	a0,0x4
    80003f18:	72450513          	addi	a0,a0,1828 # 80008638 <syscalls+0x1b0>
    80003f1c:	ffffc097          	auipc	ra,0xffffc
    80003f20:	622080e7          	jalr	1570(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f24:	40dc                	lw	a5,4(s1)
    80003f26:	0047d79b          	srliw	a5,a5,0x4
    80003f2a:	0023c597          	auipc	a1,0x23c
    80003f2e:	bae5a583          	lw	a1,-1106(a1) # 8023fad8 <sb+0x18>
    80003f32:	9dbd                	addw	a1,a1,a5
    80003f34:	4088                	lw	a0,0(s1)
    80003f36:	fffff097          	auipc	ra,0xfffff
    80003f3a:	794080e7          	jalr	1940(ra) # 800036ca <bread>
    80003f3e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f40:	05850593          	addi	a1,a0,88
    80003f44:	40dc                	lw	a5,4(s1)
    80003f46:	8bbd                	andi	a5,a5,15
    80003f48:	079a                	slli	a5,a5,0x6
    80003f4a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f4c:	00059783          	lh	a5,0(a1)
    80003f50:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f54:	00259783          	lh	a5,2(a1)
    80003f58:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f5c:	00459783          	lh	a5,4(a1)
    80003f60:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f64:	00659783          	lh	a5,6(a1)
    80003f68:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f6c:	459c                	lw	a5,8(a1)
    80003f6e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f70:	03400613          	li	a2,52
    80003f74:	05b1                	addi	a1,a1,12
    80003f76:	05048513          	addi	a0,s1,80
    80003f7a:	ffffd097          	auipc	ra,0xffffd
    80003f7e:	ee4080e7          	jalr	-284(ra) # 80000e5e <memmove>
    brelse(bp);
    80003f82:	854a                	mv	a0,s2
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	876080e7          	jalr	-1930(ra) # 800037fa <brelse>
    ip->valid = 1;
    80003f8c:	4785                	li	a5,1
    80003f8e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f90:	04449783          	lh	a5,68(s1)
    80003f94:	fbb5                	bnez	a5,80003f08 <ilock+0x24>
      panic("ilock: no type");
    80003f96:	00004517          	auipc	a0,0x4
    80003f9a:	6aa50513          	addi	a0,a0,1706 # 80008640 <syscalls+0x1b8>
    80003f9e:	ffffc097          	auipc	ra,0xffffc
    80003fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>

0000000080003fa6 <iunlock>:
{
    80003fa6:	1101                	addi	sp,sp,-32
    80003fa8:	ec06                	sd	ra,24(sp)
    80003faa:	e822                	sd	s0,16(sp)
    80003fac:	e426                	sd	s1,8(sp)
    80003fae:	e04a                	sd	s2,0(sp)
    80003fb0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003fb2:	c905                	beqz	a0,80003fe2 <iunlock+0x3c>
    80003fb4:	84aa                	mv	s1,a0
    80003fb6:	01050913          	addi	s2,a0,16
    80003fba:	854a                	mv	a0,s2
    80003fbc:	00001097          	auipc	ra,0x1
    80003fc0:	c7c080e7          	jalr	-900(ra) # 80004c38 <holdingsleep>
    80003fc4:	cd19                	beqz	a0,80003fe2 <iunlock+0x3c>
    80003fc6:	449c                	lw	a5,8(s1)
    80003fc8:	00f05d63          	blez	a5,80003fe2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fcc:	854a                	mv	a0,s2
    80003fce:	00001097          	auipc	ra,0x1
    80003fd2:	c26080e7          	jalr	-986(ra) # 80004bf4 <releasesleep>
}
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	64a2                	ld	s1,8(sp)
    80003fdc:	6902                	ld	s2,0(sp)
    80003fde:	6105                	addi	sp,sp,32
    80003fe0:	8082                	ret
    panic("iunlock");
    80003fe2:	00004517          	auipc	a0,0x4
    80003fe6:	66e50513          	addi	a0,a0,1646 # 80008650 <syscalls+0x1c8>
    80003fea:	ffffc097          	auipc	ra,0xffffc
    80003fee:	554080e7          	jalr	1364(ra) # 8000053e <panic>

0000000080003ff2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ff2:	7179                	addi	sp,sp,-48
    80003ff4:	f406                	sd	ra,40(sp)
    80003ff6:	f022                	sd	s0,32(sp)
    80003ff8:	ec26                	sd	s1,24(sp)
    80003ffa:	e84a                	sd	s2,16(sp)
    80003ffc:	e44e                	sd	s3,8(sp)
    80003ffe:	e052                	sd	s4,0(sp)
    80004000:	1800                	addi	s0,sp,48
    80004002:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004004:	05050493          	addi	s1,a0,80
    80004008:	08050913          	addi	s2,a0,128
    8000400c:	a021                	j	80004014 <itrunc+0x22>
    8000400e:	0491                	addi	s1,s1,4
    80004010:	01248d63          	beq	s1,s2,8000402a <itrunc+0x38>
    if(ip->addrs[i]){
    80004014:	408c                	lw	a1,0(s1)
    80004016:	dde5                	beqz	a1,8000400e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004018:	0009a503          	lw	a0,0(s3)
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	8f4080e7          	jalr	-1804(ra) # 80003910 <bfree>
      ip->addrs[i] = 0;
    80004024:	0004a023          	sw	zero,0(s1)
    80004028:	b7dd                	j	8000400e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000402a:	0809a583          	lw	a1,128(s3)
    8000402e:	e185                	bnez	a1,8000404e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004030:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004034:	854e                	mv	a0,s3
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	de4080e7          	jalr	-540(ra) # 80003e1a <iupdate>
}
    8000403e:	70a2                	ld	ra,40(sp)
    80004040:	7402                	ld	s0,32(sp)
    80004042:	64e2                	ld	s1,24(sp)
    80004044:	6942                	ld	s2,16(sp)
    80004046:	69a2                	ld	s3,8(sp)
    80004048:	6a02                	ld	s4,0(sp)
    8000404a:	6145                	addi	sp,sp,48
    8000404c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000404e:	0009a503          	lw	a0,0(s3)
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	678080e7          	jalr	1656(ra) # 800036ca <bread>
    8000405a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000405c:	05850493          	addi	s1,a0,88
    80004060:	45850913          	addi	s2,a0,1112
    80004064:	a021                	j	8000406c <itrunc+0x7a>
    80004066:	0491                	addi	s1,s1,4
    80004068:	01248b63          	beq	s1,s2,8000407e <itrunc+0x8c>
      if(a[j])
    8000406c:	408c                	lw	a1,0(s1)
    8000406e:	dde5                	beqz	a1,80004066 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80004070:	0009a503          	lw	a0,0(s3)
    80004074:	00000097          	auipc	ra,0x0
    80004078:	89c080e7          	jalr	-1892(ra) # 80003910 <bfree>
    8000407c:	b7ed                	j	80004066 <itrunc+0x74>
    brelse(bp);
    8000407e:	8552                	mv	a0,s4
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	77a080e7          	jalr	1914(ra) # 800037fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004088:	0809a583          	lw	a1,128(s3)
    8000408c:	0009a503          	lw	a0,0(s3)
    80004090:	00000097          	auipc	ra,0x0
    80004094:	880080e7          	jalr	-1920(ra) # 80003910 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004098:	0809a023          	sw	zero,128(s3)
    8000409c:	bf51                	j	80004030 <itrunc+0x3e>

000000008000409e <iput>:
{
    8000409e:	1101                	addi	sp,sp,-32
    800040a0:	ec06                	sd	ra,24(sp)
    800040a2:	e822                	sd	s0,16(sp)
    800040a4:	e426                	sd	s1,8(sp)
    800040a6:	e04a                	sd	s2,0(sp)
    800040a8:	1000                	addi	s0,sp,32
    800040aa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040ac:	0023c517          	auipc	a0,0x23c
    800040b0:	a3450513          	addi	a0,a0,-1484 # 8023fae0 <itable>
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	c52080e7          	jalr	-942(ra) # 80000d06 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040bc:	4498                	lw	a4,8(s1)
    800040be:	4785                	li	a5,1
    800040c0:	02f70363          	beq	a4,a5,800040e6 <iput+0x48>
  ip->ref--;
    800040c4:	449c                	lw	a5,8(s1)
    800040c6:	37fd                	addiw	a5,a5,-1
    800040c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040ca:	0023c517          	auipc	a0,0x23c
    800040ce:	a1650513          	addi	a0,a0,-1514 # 8023fae0 <itable>
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	ce8080e7          	jalr	-792(ra) # 80000dba <release>
}
    800040da:	60e2                	ld	ra,24(sp)
    800040dc:	6442                	ld	s0,16(sp)
    800040de:	64a2                	ld	s1,8(sp)
    800040e0:	6902                	ld	s2,0(sp)
    800040e2:	6105                	addi	sp,sp,32
    800040e4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040e6:	40bc                	lw	a5,64(s1)
    800040e8:	dff1                	beqz	a5,800040c4 <iput+0x26>
    800040ea:	04a49783          	lh	a5,74(s1)
    800040ee:	fbf9                	bnez	a5,800040c4 <iput+0x26>
    acquiresleep(&ip->lock);
    800040f0:	01048913          	addi	s2,s1,16
    800040f4:	854a                	mv	a0,s2
    800040f6:	00001097          	auipc	ra,0x1
    800040fa:	aa8080e7          	jalr	-1368(ra) # 80004b9e <acquiresleep>
    release(&itable.lock);
    800040fe:	0023c517          	auipc	a0,0x23c
    80004102:	9e250513          	addi	a0,a0,-1566 # 8023fae0 <itable>
    80004106:	ffffd097          	auipc	ra,0xffffd
    8000410a:	cb4080e7          	jalr	-844(ra) # 80000dba <release>
    itrunc(ip);
    8000410e:	8526                	mv	a0,s1
    80004110:	00000097          	auipc	ra,0x0
    80004114:	ee2080e7          	jalr	-286(ra) # 80003ff2 <itrunc>
    ip->type = 0;
    80004118:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000411c:	8526                	mv	a0,s1
    8000411e:	00000097          	auipc	ra,0x0
    80004122:	cfc080e7          	jalr	-772(ra) # 80003e1a <iupdate>
    ip->valid = 0;
    80004126:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000412a:	854a                	mv	a0,s2
    8000412c:	00001097          	auipc	ra,0x1
    80004130:	ac8080e7          	jalr	-1336(ra) # 80004bf4 <releasesleep>
    acquire(&itable.lock);
    80004134:	0023c517          	auipc	a0,0x23c
    80004138:	9ac50513          	addi	a0,a0,-1620 # 8023fae0 <itable>
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	bca080e7          	jalr	-1078(ra) # 80000d06 <acquire>
    80004144:	b741                	j	800040c4 <iput+0x26>

0000000080004146 <iunlockput>:
{
    80004146:	1101                	addi	sp,sp,-32
    80004148:	ec06                	sd	ra,24(sp)
    8000414a:	e822                	sd	s0,16(sp)
    8000414c:	e426                	sd	s1,8(sp)
    8000414e:	1000                	addi	s0,sp,32
    80004150:	84aa                	mv	s1,a0
  iunlock(ip);
    80004152:	00000097          	auipc	ra,0x0
    80004156:	e54080e7          	jalr	-428(ra) # 80003fa6 <iunlock>
  iput(ip);
    8000415a:	8526                	mv	a0,s1
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	f42080e7          	jalr	-190(ra) # 8000409e <iput>
}
    80004164:	60e2                	ld	ra,24(sp)
    80004166:	6442                	ld	s0,16(sp)
    80004168:	64a2                	ld	s1,8(sp)
    8000416a:	6105                	addi	sp,sp,32
    8000416c:	8082                	ret

000000008000416e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000416e:	1141                	addi	sp,sp,-16
    80004170:	e422                	sd	s0,8(sp)
    80004172:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004174:	411c                	lw	a5,0(a0)
    80004176:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004178:	415c                	lw	a5,4(a0)
    8000417a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000417c:	04451783          	lh	a5,68(a0)
    80004180:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004184:	04a51783          	lh	a5,74(a0)
    80004188:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000418c:	04c56783          	lwu	a5,76(a0)
    80004190:	e99c                	sd	a5,16(a1)
}
    80004192:	6422                	ld	s0,8(sp)
    80004194:	0141                	addi	sp,sp,16
    80004196:	8082                	ret

0000000080004198 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004198:	457c                	lw	a5,76(a0)
    8000419a:	0ed7e963          	bltu	a5,a3,8000428c <readi+0xf4>
{
    8000419e:	7159                	addi	sp,sp,-112
    800041a0:	f486                	sd	ra,104(sp)
    800041a2:	f0a2                	sd	s0,96(sp)
    800041a4:	eca6                	sd	s1,88(sp)
    800041a6:	e8ca                	sd	s2,80(sp)
    800041a8:	e4ce                	sd	s3,72(sp)
    800041aa:	e0d2                	sd	s4,64(sp)
    800041ac:	fc56                	sd	s5,56(sp)
    800041ae:	f85a                	sd	s6,48(sp)
    800041b0:	f45e                	sd	s7,40(sp)
    800041b2:	f062                	sd	s8,32(sp)
    800041b4:	ec66                	sd	s9,24(sp)
    800041b6:	e86a                	sd	s10,16(sp)
    800041b8:	e46e                	sd	s11,8(sp)
    800041ba:	1880                	addi	s0,sp,112
    800041bc:	8b2a                	mv	s6,a0
    800041be:	8bae                	mv	s7,a1
    800041c0:	8a32                	mv	s4,a2
    800041c2:	84b6                	mv	s1,a3
    800041c4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800041c6:	9f35                	addw	a4,a4,a3
    return 0;
    800041c8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041ca:	0ad76063          	bltu	a4,a3,8000426a <readi+0xd2>
  if(off + n > ip->size)
    800041ce:	00e7f463          	bgeu	a5,a4,800041d6 <readi+0x3e>
    n = ip->size - off;
    800041d2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041d6:	0a0a8963          	beqz	s5,80004288 <readi+0xf0>
    800041da:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041dc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041e0:	5c7d                	li	s8,-1
    800041e2:	a82d                	j	8000421c <readi+0x84>
    800041e4:	020d1d93          	slli	s11,s10,0x20
    800041e8:	020ddd93          	srli	s11,s11,0x20
    800041ec:	05890793          	addi	a5,s2,88
    800041f0:	86ee                	mv	a3,s11
    800041f2:	963e                	add	a2,a2,a5
    800041f4:	85d2                	mv	a1,s4
    800041f6:	855e                	mv	a0,s7
    800041f8:	ffffe097          	auipc	ra,0xffffe
    800041fc:	6da080e7          	jalr	1754(ra) # 800028d2 <either_copyout>
    80004200:	05850d63          	beq	a0,s8,8000425a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004204:	854a                	mv	a0,s2
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	5f4080e7          	jalr	1524(ra) # 800037fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000420e:	013d09bb          	addw	s3,s10,s3
    80004212:	009d04bb          	addw	s1,s10,s1
    80004216:	9a6e                	add	s4,s4,s11
    80004218:	0559f763          	bgeu	s3,s5,80004266 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000421c:	00a4d59b          	srliw	a1,s1,0xa
    80004220:	855a                	mv	a0,s6
    80004222:	00000097          	auipc	ra,0x0
    80004226:	8a2080e7          	jalr	-1886(ra) # 80003ac4 <bmap>
    8000422a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000422e:	cd85                	beqz	a1,80004266 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004230:	000b2503          	lw	a0,0(s6)
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	496080e7          	jalr	1174(ra) # 800036ca <bread>
    8000423c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423e:	3ff4f613          	andi	a2,s1,1023
    80004242:	40cc87bb          	subw	a5,s9,a2
    80004246:	413a873b          	subw	a4,s5,s3
    8000424a:	8d3e                	mv	s10,a5
    8000424c:	2781                	sext.w	a5,a5
    8000424e:	0007069b          	sext.w	a3,a4
    80004252:	f8f6f9e3          	bgeu	a3,a5,800041e4 <readi+0x4c>
    80004256:	8d3a                	mv	s10,a4
    80004258:	b771                	j	800041e4 <readi+0x4c>
      brelse(bp);
    8000425a:	854a                	mv	a0,s2
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	59e080e7          	jalr	1438(ra) # 800037fa <brelse>
      tot = -1;
    80004264:	59fd                	li	s3,-1
  }
  return tot;
    80004266:	0009851b          	sext.w	a0,s3
}
    8000426a:	70a6                	ld	ra,104(sp)
    8000426c:	7406                	ld	s0,96(sp)
    8000426e:	64e6                	ld	s1,88(sp)
    80004270:	6946                	ld	s2,80(sp)
    80004272:	69a6                	ld	s3,72(sp)
    80004274:	6a06                	ld	s4,64(sp)
    80004276:	7ae2                	ld	s5,56(sp)
    80004278:	7b42                	ld	s6,48(sp)
    8000427a:	7ba2                	ld	s7,40(sp)
    8000427c:	7c02                	ld	s8,32(sp)
    8000427e:	6ce2                	ld	s9,24(sp)
    80004280:	6d42                	ld	s10,16(sp)
    80004282:	6da2                	ld	s11,8(sp)
    80004284:	6165                	addi	sp,sp,112
    80004286:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004288:	89d6                	mv	s3,s5
    8000428a:	bff1                	j	80004266 <readi+0xce>
    return 0;
    8000428c:	4501                	li	a0,0
}
    8000428e:	8082                	ret

0000000080004290 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004290:	457c                	lw	a5,76(a0)
    80004292:	10d7e863          	bltu	a5,a3,800043a2 <writei+0x112>
{
    80004296:	7159                	addi	sp,sp,-112
    80004298:	f486                	sd	ra,104(sp)
    8000429a:	f0a2                	sd	s0,96(sp)
    8000429c:	eca6                	sd	s1,88(sp)
    8000429e:	e8ca                	sd	s2,80(sp)
    800042a0:	e4ce                	sd	s3,72(sp)
    800042a2:	e0d2                	sd	s4,64(sp)
    800042a4:	fc56                	sd	s5,56(sp)
    800042a6:	f85a                	sd	s6,48(sp)
    800042a8:	f45e                	sd	s7,40(sp)
    800042aa:	f062                	sd	s8,32(sp)
    800042ac:	ec66                	sd	s9,24(sp)
    800042ae:	e86a                	sd	s10,16(sp)
    800042b0:	e46e                	sd	s11,8(sp)
    800042b2:	1880                	addi	s0,sp,112
    800042b4:	8aaa                	mv	s5,a0
    800042b6:	8bae                	mv	s7,a1
    800042b8:	8a32                	mv	s4,a2
    800042ba:	8936                	mv	s2,a3
    800042bc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042be:	00e687bb          	addw	a5,a3,a4
    800042c2:	0ed7e263          	bltu	a5,a3,800043a6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042c6:	00043737          	lui	a4,0x43
    800042ca:	0ef76063          	bltu	a4,a5,800043aa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042ce:	0c0b0863          	beqz	s6,8000439e <writei+0x10e>
    800042d2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800042d4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042d8:	5c7d                	li	s8,-1
    800042da:	a091                	j	8000431e <writei+0x8e>
    800042dc:	020d1d93          	slli	s11,s10,0x20
    800042e0:	020ddd93          	srli	s11,s11,0x20
    800042e4:	05848793          	addi	a5,s1,88
    800042e8:	86ee                	mv	a3,s11
    800042ea:	8652                	mv	a2,s4
    800042ec:	85de                	mv	a1,s7
    800042ee:	953e                	add	a0,a0,a5
    800042f0:	ffffe097          	auipc	ra,0xffffe
    800042f4:	638080e7          	jalr	1592(ra) # 80002928 <either_copyin>
    800042f8:	07850263          	beq	a0,s8,8000435c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042fc:	8526                	mv	a0,s1
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	780080e7          	jalr	1920(ra) # 80004a7e <log_write>
    brelse(bp);
    80004306:	8526                	mv	a0,s1
    80004308:	fffff097          	auipc	ra,0xfffff
    8000430c:	4f2080e7          	jalr	1266(ra) # 800037fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004310:	013d09bb          	addw	s3,s10,s3
    80004314:	012d093b          	addw	s2,s10,s2
    80004318:	9a6e                	add	s4,s4,s11
    8000431a:	0569f663          	bgeu	s3,s6,80004366 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000431e:	00a9559b          	srliw	a1,s2,0xa
    80004322:	8556                	mv	a0,s5
    80004324:	fffff097          	auipc	ra,0xfffff
    80004328:	7a0080e7          	jalr	1952(ra) # 80003ac4 <bmap>
    8000432c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004330:	c99d                	beqz	a1,80004366 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004332:	000aa503          	lw	a0,0(s5)
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	394080e7          	jalr	916(ra) # 800036ca <bread>
    8000433e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004340:	3ff97513          	andi	a0,s2,1023
    80004344:	40ac87bb          	subw	a5,s9,a0
    80004348:	413b073b          	subw	a4,s6,s3
    8000434c:	8d3e                	mv	s10,a5
    8000434e:	2781                	sext.w	a5,a5
    80004350:	0007069b          	sext.w	a3,a4
    80004354:	f8f6f4e3          	bgeu	a3,a5,800042dc <writei+0x4c>
    80004358:	8d3a                	mv	s10,a4
    8000435a:	b749                	j	800042dc <writei+0x4c>
      brelse(bp);
    8000435c:	8526                	mv	a0,s1
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	49c080e7          	jalr	1180(ra) # 800037fa <brelse>
  }

  if(off > ip->size)
    80004366:	04caa783          	lw	a5,76(s5)
    8000436a:	0127f463          	bgeu	a5,s2,80004372 <writei+0xe2>
    ip->size = off;
    8000436e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004372:	8556                	mv	a0,s5
    80004374:	00000097          	auipc	ra,0x0
    80004378:	aa6080e7          	jalr	-1370(ra) # 80003e1a <iupdate>

  return tot;
    8000437c:	0009851b          	sext.w	a0,s3
}
    80004380:	70a6                	ld	ra,104(sp)
    80004382:	7406                	ld	s0,96(sp)
    80004384:	64e6                	ld	s1,88(sp)
    80004386:	6946                	ld	s2,80(sp)
    80004388:	69a6                	ld	s3,72(sp)
    8000438a:	6a06                	ld	s4,64(sp)
    8000438c:	7ae2                	ld	s5,56(sp)
    8000438e:	7b42                	ld	s6,48(sp)
    80004390:	7ba2                	ld	s7,40(sp)
    80004392:	7c02                	ld	s8,32(sp)
    80004394:	6ce2                	ld	s9,24(sp)
    80004396:	6d42                	ld	s10,16(sp)
    80004398:	6da2                	ld	s11,8(sp)
    8000439a:	6165                	addi	sp,sp,112
    8000439c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000439e:	89da                	mv	s3,s6
    800043a0:	bfc9                	j	80004372 <writei+0xe2>
    return -1;
    800043a2:	557d                	li	a0,-1
}
    800043a4:	8082                	ret
    return -1;
    800043a6:	557d                	li	a0,-1
    800043a8:	bfe1                	j	80004380 <writei+0xf0>
    return -1;
    800043aa:	557d                	li	a0,-1
    800043ac:	bfd1                	j	80004380 <writei+0xf0>

00000000800043ae <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800043ae:	1141                	addi	sp,sp,-16
    800043b0:	e406                	sd	ra,8(sp)
    800043b2:	e022                	sd	s0,0(sp)
    800043b4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043b6:	4639                	li	a2,14
    800043b8:	ffffd097          	auipc	ra,0xffffd
    800043bc:	b1a080e7          	jalr	-1254(ra) # 80000ed2 <strncmp>
}
    800043c0:	60a2                	ld	ra,8(sp)
    800043c2:	6402                	ld	s0,0(sp)
    800043c4:	0141                	addi	sp,sp,16
    800043c6:	8082                	ret

00000000800043c8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043c8:	7139                	addi	sp,sp,-64
    800043ca:	fc06                	sd	ra,56(sp)
    800043cc:	f822                	sd	s0,48(sp)
    800043ce:	f426                	sd	s1,40(sp)
    800043d0:	f04a                	sd	s2,32(sp)
    800043d2:	ec4e                	sd	s3,24(sp)
    800043d4:	e852                	sd	s4,16(sp)
    800043d6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043d8:	04451703          	lh	a4,68(a0)
    800043dc:	4785                	li	a5,1
    800043de:	00f71a63          	bne	a4,a5,800043f2 <dirlookup+0x2a>
    800043e2:	892a                	mv	s2,a0
    800043e4:	89ae                	mv	s3,a1
    800043e6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043e8:	457c                	lw	a5,76(a0)
    800043ea:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043ec:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043ee:	e79d                	bnez	a5,8000441c <dirlookup+0x54>
    800043f0:	a8a5                	j	80004468 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043f2:	00004517          	auipc	a0,0x4
    800043f6:	26650513          	addi	a0,a0,614 # 80008658 <syscalls+0x1d0>
    800043fa:	ffffc097          	auipc	ra,0xffffc
    800043fe:	144080e7          	jalr	324(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004402:	00004517          	auipc	a0,0x4
    80004406:	26e50513          	addi	a0,a0,622 # 80008670 <syscalls+0x1e8>
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	134080e7          	jalr	308(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004412:	24c1                	addiw	s1,s1,16
    80004414:	04c92783          	lw	a5,76(s2)
    80004418:	04f4f763          	bgeu	s1,a5,80004466 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000441c:	4741                	li	a4,16
    8000441e:	86a6                	mv	a3,s1
    80004420:	fc040613          	addi	a2,s0,-64
    80004424:	4581                	li	a1,0
    80004426:	854a                	mv	a0,s2
    80004428:	00000097          	auipc	ra,0x0
    8000442c:	d70080e7          	jalr	-656(ra) # 80004198 <readi>
    80004430:	47c1                	li	a5,16
    80004432:	fcf518e3          	bne	a0,a5,80004402 <dirlookup+0x3a>
    if(de.inum == 0)
    80004436:	fc045783          	lhu	a5,-64(s0)
    8000443a:	dfe1                	beqz	a5,80004412 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000443c:	fc240593          	addi	a1,s0,-62
    80004440:	854e                	mv	a0,s3
    80004442:	00000097          	auipc	ra,0x0
    80004446:	f6c080e7          	jalr	-148(ra) # 800043ae <namecmp>
    8000444a:	f561                	bnez	a0,80004412 <dirlookup+0x4a>
      if(poff)
    8000444c:	000a0463          	beqz	s4,80004454 <dirlookup+0x8c>
        *poff = off;
    80004450:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004454:	fc045583          	lhu	a1,-64(s0)
    80004458:	00092503          	lw	a0,0(s2)
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	750080e7          	jalr	1872(ra) # 80003bac <iget>
    80004464:	a011                	j	80004468 <dirlookup+0xa0>
  return 0;
    80004466:	4501                	li	a0,0
}
    80004468:	70e2                	ld	ra,56(sp)
    8000446a:	7442                	ld	s0,48(sp)
    8000446c:	74a2                	ld	s1,40(sp)
    8000446e:	7902                	ld	s2,32(sp)
    80004470:	69e2                	ld	s3,24(sp)
    80004472:	6a42                	ld	s4,16(sp)
    80004474:	6121                	addi	sp,sp,64
    80004476:	8082                	ret

0000000080004478 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004478:	711d                	addi	sp,sp,-96
    8000447a:	ec86                	sd	ra,88(sp)
    8000447c:	e8a2                	sd	s0,80(sp)
    8000447e:	e4a6                	sd	s1,72(sp)
    80004480:	e0ca                	sd	s2,64(sp)
    80004482:	fc4e                	sd	s3,56(sp)
    80004484:	f852                	sd	s4,48(sp)
    80004486:	f456                	sd	s5,40(sp)
    80004488:	f05a                	sd	s6,32(sp)
    8000448a:	ec5e                	sd	s7,24(sp)
    8000448c:	e862                	sd	s8,16(sp)
    8000448e:	e466                	sd	s9,8(sp)
    80004490:	1080                	addi	s0,sp,96
    80004492:	84aa                	mv	s1,a0
    80004494:	8aae                	mv	s5,a1
    80004496:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004498:	00054703          	lbu	a4,0(a0)
    8000449c:	02f00793          	li	a5,47
    800044a0:	02f70363          	beq	a4,a5,800044c6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	700080e7          	jalr	1792(ra) # 80001ba4 <myproc>
    800044ac:	15053503          	ld	a0,336(a0)
    800044b0:	00000097          	auipc	ra,0x0
    800044b4:	9f6080e7          	jalr	-1546(ra) # 80003ea6 <idup>
    800044b8:	89aa                	mv	s3,a0
  while(*path == '/')
    800044ba:	02f00913          	li	s2,47
  len = path - s;
    800044be:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044c0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044c2:	4b85                	li	s7,1
    800044c4:	a865                	j	8000457c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044c6:	4585                	li	a1,1
    800044c8:	4505                	li	a0,1
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	6e2080e7          	jalr	1762(ra) # 80003bac <iget>
    800044d2:	89aa                	mv	s3,a0
    800044d4:	b7dd                	j	800044ba <namex+0x42>
      iunlockput(ip);
    800044d6:	854e                	mv	a0,s3
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	c6e080e7          	jalr	-914(ra) # 80004146 <iunlockput>
      return 0;
    800044e0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044e2:	854e                	mv	a0,s3
    800044e4:	60e6                	ld	ra,88(sp)
    800044e6:	6446                	ld	s0,80(sp)
    800044e8:	64a6                	ld	s1,72(sp)
    800044ea:	6906                	ld	s2,64(sp)
    800044ec:	79e2                	ld	s3,56(sp)
    800044ee:	7a42                	ld	s4,48(sp)
    800044f0:	7aa2                	ld	s5,40(sp)
    800044f2:	7b02                	ld	s6,32(sp)
    800044f4:	6be2                	ld	s7,24(sp)
    800044f6:	6c42                	ld	s8,16(sp)
    800044f8:	6ca2                	ld	s9,8(sp)
    800044fa:	6125                	addi	sp,sp,96
    800044fc:	8082                	ret
      iunlock(ip);
    800044fe:	854e                	mv	a0,s3
    80004500:	00000097          	auipc	ra,0x0
    80004504:	aa6080e7          	jalr	-1370(ra) # 80003fa6 <iunlock>
      return ip;
    80004508:	bfe9                	j	800044e2 <namex+0x6a>
      iunlockput(ip);
    8000450a:	854e                	mv	a0,s3
    8000450c:	00000097          	auipc	ra,0x0
    80004510:	c3a080e7          	jalr	-966(ra) # 80004146 <iunlockput>
      return 0;
    80004514:	89e6                	mv	s3,s9
    80004516:	b7f1                	j	800044e2 <namex+0x6a>
  len = path - s;
    80004518:	40b48633          	sub	a2,s1,a1
    8000451c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004520:	099c5463          	bge	s8,s9,800045a8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004524:	4639                	li	a2,14
    80004526:	8552                	mv	a0,s4
    80004528:	ffffd097          	auipc	ra,0xffffd
    8000452c:	936080e7          	jalr	-1738(ra) # 80000e5e <memmove>
  while(*path == '/')
    80004530:	0004c783          	lbu	a5,0(s1)
    80004534:	01279763          	bne	a5,s2,80004542 <namex+0xca>
    path++;
    80004538:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000453a:	0004c783          	lbu	a5,0(s1)
    8000453e:	ff278de3          	beq	a5,s2,80004538 <namex+0xc0>
    ilock(ip);
    80004542:	854e                	mv	a0,s3
    80004544:	00000097          	auipc	ra,0x0
    80004548:	9a0080e7          	jalr	-1632(ra) # 80003ee4 <ilock>
    if(ip->type != T_DIR){
    8000454c:	04499783          	lh	a5,68(s3)
    80004550:	f97793e3          	bne	a5,s7,800044d6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004554:	000a8563          	beqz	s5,8000455e <namex+0xe6>
    80004558:	0004c783          	lbu	a5,0(s1)
    8000455c:	d3cd                	beqz	a5,800044fe <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000455e:	865a                	mv	a2,s6
    80004560:	85d2                	mv	a1,s4
    80004562:	854e                	mv	a0,s3
    80004564:	00000097          	auipc	ra,0x0
    80004568:	e64080e7          	jalr	-412(ra) # 800043c8 <dirlookup>
    8000456c:	8caa                	mv	s9,a0
    8000456e:	dd51                	beqz	a0,8000450a <namex+0x92>
    iunlockput(ip);
    80004570:	854e                	mv	a0,s3
    80004572:	00000097          	auipc	ra,0x0
    80004576:	bd4080e7          	jalr	-1068(ra) # 80004146 <iunlockput>
    ip = next;
    8000457a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000457c:	0004c783          	lbu	a5,0(s1)
    80004580:	05279763          	bne	a5,s2,800045ce <namex+0x156>
    path++;
    80004584:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004586:	0004c783          	lbu	a5,0(s1)
    8000458a:	ff278de3          	beq	a5,s2,80004584 <namex+0x10c>
  if(*path == 0)
    8000458e:	c79d                	beqz	a5,800045bc <namex+0x144>
    path++;
    80004590:	85a6                	mv	a1,s1
  len = path - s;
    80004592:	8cda                	mv	s9,s6
    80004594:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004596:	01278963          	beq	a5,s2,800045a8 <namex+0x130>
    8000459a:	dfbd                	beqz	a5,80004518 <namex+0xa0>
    path++;
    8000459c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000459e:	0004c783          	lbu	a5,0(s1)
    800045a2:	ff279ce3          	bne	a5,s2,8000459a <namex+0x122>
    800045a6:	bf8d                	j	80004518 <namex+0xa0>
    memmove(name, s, len);
    800045a8:	2601                	sext.w	a2,a2
    800045aa:	8552                	mv	a0,s4
    800045ac:	ffffd097          	auipc	ra,0xffffd
    800045b0:	8b2080e7          	jalr	-1870(ra) # 80000e5e <memmove>
    name[len] = 0;
    800045b4:	9cd2                	add	s9,s9,s4
    800045b6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045ba:	bf9d                	j	80004530 <namex+0xb8>
  if(nameiparent){
    800045bc:	f20a83e3          	beqz	s5,800044e2 <namex+0x6a>
    iput(ip);
    800045c0:	854e                	mv	a0,s3
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	adc080e7          	jalr	-1316(ra) # 8000409e <iput>
    return 0;
    800045ca:	4981                	li	s3,0
    800045cc:	bf19                	j	800044e2 <namex+0x6a>
  if(*path == 0)
    800045ce:	d7fd                	beqz	a5,800045bc <namex+0x144>
  while(*path != '/' && *path != 0)
    800045d0:	0004c783          	lbu	a5,0(s1)
    800045d4:	85a6                	mv	a1,s1
    800045d6:	b7d1                	j	8000459a <namex+0x122>

00000000800045d8 <dirlink>:
{
    800045d8:	7139                	addi	sp,sp,-64
    800045da:	fc06                	sd	ra,56(sp)
    800045dc:	f822                	sd	s0,48(sp)
    800045de:	f426                	sd	s1,40(sp)
    800045e0:	f04a                	sd	s2,32(sp)
    800045e2:	ec4e                	sd	s3,24(sp)
    800045e4:	e852                	sd	s4,16(sp)
    800045e6:	0080                	addi	s0,sp,64
    800045e8:	892a                	mv	s2,a0
    800045ea:	8a2e                	mv	s4,a1
    800045ec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045ee:	4601                	li	a2,0
    800045f0:	00000097          	auipc	ra,0x0
    800045f4:	dd8080e7          	jalr	-552(ra) # 800043c8 <dirlookup>
    800045f8:	e93d                	bnez	a0,8000466e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045fa:	04c92483          	lw	s1,76(s2)
    800045fe:	c49d                	beqz	s1,8000462c <dirlink+0x54>
    80004600:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004602:	4741                	li	a4,16
    80004604:	86a6                	mv	a3,s1
    80004606:	fc040613          	addi	a2,s0,-64
    8000460a:	4581                	li	a1,0
    8000460c:	854a                	mv	a0,s2
    8000460e:	00000097          	auipc	ra,0x0
    80004612:	b8a080e7          	jalr	-1142(ra) # 80004198 <readi>
    80004616:	47c1                	li	a5,16
    80004618:	06f51163          	bne	a0,a5,8000467a <dirlink+0xa2>
    if(de.inum == 0)
    8000461c:	fc045783          	lhu	a5,-64(s0)
    80004620:	c791                	beqz	a5,8000462c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004622:	24c1                	addiw	s1,s1,16
    80004624:	04c92783          	lw	a5,76(s2)
    80004628:	fcf4ede3          	bltu	s1,a5,80004602 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000462c:	4639                	li	a2,14
    8000462e:	85d2                	mv	a1,s4
    80004630:	fc240513          	addi	a0,s0,-62
    80004634:	ffffd097          	auipc	ra,0xffffd
    80004638:	8da080e7          	jalr	-1830(ra) # 80000f0e <strncpy>
  de.inum = inum;
    8000463c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004640:	4741                	li	a4,16
    80004642:	86a6                	mv	a3,s1
    80004644:	fc040613          	addi	a2,s0,-64
    80004648:	4581                	li	a1,0
    8000464a:	854a                	mv	a0,s2
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	c44080e7          	jalr	-956(ra) # 80004290 <writei>
    80004654:	1541                	addi	a0,a0,-16
    80004656:	00a03533          	snez	a0,a0
    8000465a:	40a00533          	neg	a0,a0
}
    8000465e:	70e2                	ld	ra,56(sp)
    80004660:	7442                	ld	s0,48(sp)
    80004662:	74a2                	ld	s1,40(sp)
    80004664:	7902                	ld	s2,32(sp)
    80004666:	69e2                	ld	s3,24(sp)
    80004668:	6a42                	ld	s4,16(sp)
    8000466a:	6121                	addi	sp,sp,64
    8000466c:	8082                	ret
    iput(ip);
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	a30080e7          	jalr	-1488(ra) # 8000409e <iput>
    return -1;
    80004676:	557d                	li	a0,-1
    80004678:	b7dd                	j	8000465e <dirlink+0x86>
      panic("dirlink read");
    8000467a:	00004517          	auipc	a0,0x4
    8000467e:	00650513          	addi	a0,a0,6 # 80008680 <syscalls+0x1f8>
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	ebc080e7          	jalr	-324(ra) # 8000053e <panic>

000000008000468a <namei>:

struct inode*
namei(char *path)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004692:	fe040613          	addi	a2,s0,-32
    80004696:	4581                	li	a1,0
    80004698:	00000097          	auipc	ra,0x0
    8000469c:	de0080e7          	jalr	-544(ra) # 80004478 <namex>
}
    800046a0:	60e2                	ld	ra,24(sp)
    800046a2:	6442                	ld	s0,16(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret

00000000800046a8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046a8:	1141                	addi	sp,sp,-16
    800046aa:	e406                	sd	ra,8(sp)
    800046ac:	e022                	sd	s0,0(sp)
    800046ae:	0800                	addi	s0,sp,16
    800046b0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046b2:	4585                	li	a1,1
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	dc4080e7          	jalr	-572(ra) # 80004478 <namex>
}
    800046bc:	60a2                	ld	ra,8(sp)
    800046be:	6402                	ld	s0,0(sp)
    800046c0:	0141                	addi	sp,sp,16
    800046c2:	8082                	ret

00000000800046c4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800046c4:	1101                	addi	sp,sp,-32
    800046c6:	ec06                	sd	ra,24(sp)
    800046c8:	e822                	sd	s0,16(sp)
    800046ca:	e426                	sd	s1,8(sp)
    800046cc:	e04a                	sd	s2,0(sp)
    800046ce:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800046d0:	0023d917          	auipc	s2,0x23d
    800046d4:	eb890913          	addi	s2,s2,-328 # 80241588 <log>
    800046d8:	01892583          	lw	a1,24(s2)
    800046dc:	02892503          	lw	a0,40(s2)
    800046e0:	fffff097          	auipc	ra,0xfffff
    800046e4:	fea080e7          	jalr	-22(ra) # 800036ca <bread>
    800046e8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800046ea:	02c92683          	lw	a3,44(s2)
    800046ee:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800046f0:	02d05763          	blez	a3,8000471e <write_head+0x5a>
    800046f4:	0023d797          	auipc	a5,0x23d
    800046f8:	ec478793          	addi	a5,a5,-316 # 802415b8 <log+0x30>
    800046fc:	05c50713          	addi	a4,a0,92
    80004700:	36fd                	addiw	a3,a3,-1
    80004702:	1682                	slli	a3,a3,0x20
    80004704:	9281                	srli	a3,a3,0x20
    80004706:	068a                	slli	a3,a3,0x2
    80004708:	0023d617          	auipc	a2,0x23d
    8000470c:	eb460613          	addi	a2,a2,-332 # 802415bc <log+0x34>
    80004710:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004712:	4390                	lw	a2,0(a5)
    80004714:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004716:	0791                	addi	a5,a5,4
    80004718:	0711                	addi	a4,a4,4
    8000471a:	fed79ce3          	bne	a5,a3,80004712 <write_head+0x4e>
  }
  bwrite(buf);
    8000471e:	8526                	mv	a0,s1
    80004720:	fffff097          	auipc	ra,0xfffff
    80004724:	09c080e7          	jalr	156(ra) # 800037bc <bwrite>
  brelse(buf);
    80004728:	8526                	mv	a0,s1
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	0d0080e7          	jalr	208(ra) # 800037fa <brelse>
}
    80004732:	60e2                	ld	ra,24(sp)
    80004734:	6442                	ld	s0,16(sp)
    80004736:	64a2                	ld	s1,8(sp)
    80004738:	6902                	ld	s2,0(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000473e:	0023d797          	auipc	a5,0x23d
    80004742:	e767a783          	lw	a5,-394(a5) # 802415b4 <log+0x2c>
    80004746:	0af05d63          	blez	a5,80004800 <install_trans+0xc2>
{
    8000474a:	7139                	addi	sp,sp,-64
    8000474c:	fc06                	sd	ra,56(sp)
    8000474e:	f822                	sd	s0,48(sp)
    80004750:	f426                	sd	s1,40(sp)
    80004752:	f04a                	sd	s2,32(sp)
    80004754:	ec4e                	sd	s3,24(sp)
    80004756:	e852                	sd	s4,16(sp)
    80004758:	e456                	sd	s5,8(sp)
    8000475a:	e05a                	sd	s6,0(sp)
    8000475c:	0080                	addi	s0,sp,64
    8000475e:	8b2a                	mv	s6,a0
    80004760:	0023da97          	auipc	s5,0x23d
    80004764:	e58a8a93          	addi	s5,s5,-424 # 802415b8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004768:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000476a:	0023d997          	auipc	s3,0x23d
    8000476e:	e1e98993          	addi	s3,s3,-482 # 80241588 <log>
    80004772:	a00d                	j	80004794 <install_trans+0x56>
    brelse(lbuf);
    80004774:	854a                	mv	a0,s2
    80004776:	fffff097          	auipc	ra,0xfffff
    8000477a:	084080e7          	jalr	132(ra) # 800037fa <brelse>
    brelse(dbuf);
    8000477e:	8526                	mv	a0,s1
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	07a080e7          	jalr	122(ra) # 800037fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004788:	2a05                	addiw	s4,s4,1
    8000478a:	0a91                	addi	s5,s5,4
    8000478c:	02c9a783          	lw	a5,44(s3)
    80004790:	04fa5e63          	bge	s4,a5,800047ec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004794:	0189a583          	lw	a1,24(s3)
    80004798:	014585bb          	addw	a1,a1,s4
    8000479c:	2585                	addiw	a1,a1,1
    8000479e:	0289a503          	lw	a0,40(s3)
    800047a2:	fffff097          	auipc	ra,0xfffff
    800047a6:	f28080e7          	jalr	-216(ra) # 800036ca <bread>
    800047aa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800047ac:	000aa583          	lw	a1,0(s5)
    800047b0:	0289a503          	lw	a0,40(s3)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	f16080e7          	jalr	-234(ra) # 800036ca <bread>
    800047bc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800047be:	40000613          	li	a2,1024
    800047c2:	05890593          	addi	a1,s2,88
    800047c6:	05850513          	addi	a0,a0,88
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	694080e7          	jalr	1684(ra) # 80000e5e <memmove>
    bwrite(dbuf);  // write dst to disk
    800047d2:	8526                	mv	a0,s1
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	fe8080e7          	jalr	-24(ra) # 800037bc <bwrite>
    if(recovering == 0)
    800047dc:	f80b1ce3          	bnez	s6,80004774 <install_trans+0x36>
      bunpin(dbuf);
    800047e0:	8526                	mv	a0,s1
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	0f2080e7          	jalr	242(ra) # 800038d4 <bunpin>
    800047ea:	b769                	j	80004774 <install_trans+0x36>
}
    800047ec:	70e2                	ld	ra,56(sp)
    800047ee:	7442                	ld	s0,48(sp)
    800047f0:	74a2                	ld	s1,40(sp)
    800047f2:	7902                	ld	s2,32(sp)
    800047f4:	69e2                	ld	s3,24(sp)
    800047f6:	6a42                	ld	s4,16(sp)
    800047f8:	6aa2                	ld	s5,8(sp)
    800047fa:	6b02                	ld	s6,0(sp)
    800047fc:	6121                	addi	sp,sp,64
    800047fe:	8082                	ret
    80004800:	8082                	ret

0000000080004802 <initlog>:
{
    80004802:	7179                	addi	sp,sp,-48
    80004804:	f406                	sd	ra,40(sp)
    80004806:	f022                	sd	s0,32(sp)
    80004808:	ec26                	sd	s1,24(sp)
    8000480a:	e84a                	sd	s2,16(sp)
    8000480c:	e44e                	sd	s3,8(sp)
    8000480e:	1800                	addi	s0,sp,48
    80004810:	892a                	mv	s2,a0
    80004812:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004814:	0023d497          	auipc	s1,0x23d
    80004818:	d7448493          	addi	s1,s1,-652 # 80241588 <log>
    8000481c:	00004597          	auipc	a1,0x4
    80004820:	e7458593          	addi	a1,a1,-396 # 80008690 <syscalls+0x208>
    80004824:	8526                	mv	a0,s1
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	450080e7          	jalr	1104(ra) # 80000c76 <initlock>
  log.start = sb->logstart;
    8000482e:	0149a583          	lw	a1,20(s3)
    80004832:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004834:	0109a783          	lw	a5,16(s3)
    80004838:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000483a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000483e:	854a                	mv	a0,s2
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	e8a080e7          	jalr	-374(ra) # 800036ca <bread>
  log.lh.n = lh->n;
    80004848:	4d34                	lw	a3,88(a0)
    8000484a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000484c:	02d05563          	blez	a3,80004876 <initlog+0x74>
    80004850:	05c50793          	addi	a5,a0,92
    80004854:	0023d717          	auipc	a4,0x23d
    80004858:	d6470713          	addi	a4,a4,-668 # 802415b8 <log+0x30>
    8000485c:	36fd                	addiw	a3,a3,-1
    8000485e:	1682                	slli	a3,a3,0x20
    80004860:	9281                	srli	a3,a3,0x20
    80004862:	068a                	slli	a3,a3,0x2
    80004864:	06050613          	addi	a2,a0,96
    80004868:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000486a:	4390                	lw	a2,0(a5)
    8000486c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000486e:	0791                	addi	a5,a5,4
    80004870:	0711                	addi	a4,a4,4
    80004872:	fed79ce3          	bne	a5,a3,8000486a <initlog+0x68>
  brelse(buf);
    80004876:	fffff097          	auipc	ra,0xfffff
    8000487a:	f84080e7          	jalr	-124(ra) # 800037fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000487e:	4505                	li	a0,1
    80004880:	00000097          	auipc	ra,0x0
    80004884:	ebe080e7          	jalr	-322(ra) # 8000473e <install_trans>
  log.lh.n = 0;
    80004888:	0023d797          	auipc	a5,0x23d
    8000488c:	d207a623          	sw	zero,-724(a5) # 802415b4 <log+0x2c>
  write_head(); // clear the log
    80004890:	00000097          	auipc	ra,0x0
    80004894:	e34080e7          	jalr	-460(ra) # 800046c4 <write_head>
}
    80004898:	70a2                	ld	ra,40(sp)
    8000489a:	7402                	ld	s0,32(sp)
    8000489c:	64e2                	ld	s1,24(sp)
    8000489e:	6942                	ld	s2,16(sp)
    800048a0:	69a2                	ld	s3,8(sp)
    800048a2:	6145                	addi	sp,sp,48
    800048a4:	8082                	ret

00000000800048a6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800048a6:	1101                	addi	sp,sp,-32
    800048a8:	ec06                	sd	ra,24(sp)
    800048aa:	e822                	sd	s0,16(sp)
    800048ac:	e426                	sd	s1,8(sp)
    800048ae:	e04a                	sd	s2,0(sp)
    800048b0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800048b2:	0023d517          	auipc	a0,0x23d
    800048b6:	cd650513          	addi	a0,a0,-810 # 80241588 <log>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	44c080e7          	jalr	1100(ra) # 80000d06 <acquire>
  while(1){
    if(log.committing){
    800048c2:	0023d497          	auipc	s1,0x23d
    800048c6:	cc648493          	addi	s1,s1,-826 # 80241588 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048ca:	4979                	li	s2,30
    800048cc:	a039                	j	800048da <begin_op+0x34>
      sleep(&log, &log.lock);
    800048ce:	85a6                	mv	a1,s1
    800048d0:	8526                	mv	a0,s1
    800048d2:	ffffe097          	auipc	ra,0xffffe
    800048d6:	bec080e7          	jalr	-1044(ra) # 800024be <sleep>
    if(log.committing){
    800048da:	50dc                	lw	a5,36(s1)
    800048dc:	fbed                	bnez	a5,800048ce <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800048de:	509c                	lw	a5,32(s1)
    800048e0:	0017871b          	addiw	a4,a5,1
    800048e4:	0007069b          	sext.w	a3,a4
    800048e8:	0027179b          	slliw	a5,a4,0x2
    800048ec:	9fb9                	addw	a5,a5,a4
    800048ee:	0017979b          	slliw	a5,a5,0x1
    800048f2:	54d8                	lw	a4,44(s1)
    800048f4:	9fb9                	addw	a5,a5,a4
    800048f6:	00f95963          	bge	s2,a5,80004908 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800048fa:	85a6                	mv	a1,s1
    800048fc:	8526                	mv	a0,s1
    800048fe:	ffffe097          	auipc	ra,0xffffe
    80004902:	bc0080e7          	jalr	-1088(ra) # 800024be <sleep>
    80004906:	bfd1                	j	800048da <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004908:	0023d517          	auipc	a0,0x23d
    8000490c:	c8050513          	addi	a0,a0,-896 # 80241588 <log>
    80004910:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	4a8080e7          	jalr	1192(ra) # 80000dba <release>
      break;
    }
  }
}
    8000491a:	60e2                	ld	ra,24(sp)
    8000491c:	6442                	ld	s0,16(sp)
    8000491e:	64a2                	ld	s1,8(sp)
    80004920:	6902                	ld	s2,0(sp)
    80004922:	6105                	addi	sp,sp,32
    80004924:	8082                	ret

0000000080004926 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004926:	7139                	addi	sp,sp,-64
    80004928:	fc06                	sd	ra,56(sp)
    8000492a:	f822                	sd	s0,48(sp)
    8000492c:	f426                	sd	s1,40(sp)
    8000492e:	f04a                	sd	s2,32(sp)
    80004930:	ec4e                	sd	s3,24(sp)
    80004932:	e852                	sd	s4,16(sp)
    80004934:	e456                	sd	s5,8(sp)
    80004936:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004938:	0023d497          	auipc	s1,0x23d
    8000493c:	c5048493          	addi	s1,s1,-944 # 80241588 <log>
    80004940:	8526                	mv	a0,s1
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	3c4080e7          	jalr	964(ra) # 80000d06 <acquire>
  log.outstanding -= 1;
    8000494a:	509c                	lw	a5,32(s1)
    8000494c:	37fd                	addiw	a5,a5,-1
    8000494e:	0007891b          	sext.w	s2,a5
    80004952:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004954:	50dc                	lw	a5,36(s1)
    80004956:	e7b9                	bnez	a5,800049a4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004958:	04091e63          	bnez	s2,800049b4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000495c:	0023d497          	auipc	s1,0x23d
    80004960:	c2c48493          	addi	s1,s1,-980 # 80241588 <log>
    80004964:	4785                	li	a5,1
    80004966:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004968:	8526                	mv	a0,s1
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	450080e7          	jalr	1104(ra) # 80000dba <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004972:	54dc                	lw	a5,44(s1)
    80004974:	06f04763          	bgtz	a5,800049e2 <end_op+0xbc>
    acquire(&log.lock);
    80004978:	0023d497          	auipc	s1,0x23d
    8000497c:	c1048493          	addi	s1,s1,-1008 # 80241588 <log>
    80004980:	8526                	mv	a0,s1
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	384080e7          	jalr	900(ra) # 80000d06 <acquire>
    log.committing = 0;
    8000498a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000498e:	8526                	mv	a0,s1
    80004990:	ffffe097          	auipc	ra,0xffffe
    80004994:	b92080e7          	jalr	-1134(ra) # 80002522 <wakeup>
    release(&log.lock);
    80004998:	8526                	mv	a0,s1
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	420080e7          	jalr	1056(ra) # 80000dba <release>
}
    800049a2:	a03d                	j	800049d0 <end_op+0xaa>
    panic("log.committing");
    800049a4:	00004517          	auipc	a0,0x4
    800049a8:	cf450513          	addi	a0,a0,-780 # 80008698 <syscalls+0x210>
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	b92080e7          	jalr	-1134(ra) # 8000053e <panic>
    wakeup(&log);
    800049b4:	0023d497          	auipc	s1,0x23d
    800049b8:	bd448493          	addi	s1,s1,-1068 # 80241588 <log>
    800049bc:	8526                	mv	a0,s1
    800049be:	ffffe097          	auipc	ra,0xffffe
    800049c2:	b64080e7          	jalr	-1180(ra) # 80002522 <wakeup>
  release(&log.lock);
    800049c6:	8526                	mv	a0,s1
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	3f2080e7          	jalr	1010(ra) # 80000dba <release>
}
    800049d0:	70e2                	ld	ra,56(sp)
    800049d2:	7442                	ld	s0,48(sp)
    800049d4:	74a2                	ld	s1,40(sp)
    800049d6:	7902                	ld	s2,32(sp)
    800049d8:	69e2                	ld	s3,24(sp)
    800049da:	6a42                	ld	s4,16(sp)
    800049dc:	6aa2                	ld	s5,8(sp)
    800049de:	6121                	addi	sp,sp,64
    800049e0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800049e2:	0023da97          	auipc	s5,0x23d
    800049e6:	bd6a8a93          	addi	s5,s5,-1066 # 802415b8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800049ea:	0023da17          	auipc	s4,0x23d
    800049ee:	b9ea0a13          	addi	s4,s4,-1122 # 80241588 <log>
    800049f2:	018a2583          	lw	a1,24(s4)
    800049f6:	012585bb          	addw	a1,a1,s2
    800049fa:	2585                	addiw	a1,a1,1
    800049fc:	028a2503          	lw	a0,40(s4)
    80004a00:	fffff097          	auipc	ra,0xfffff
    80004a04:	cca080e7          	jalr	-822(ra) # 800036ca <bread>
    80004a08:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004a0a:	000aa583          	lw	a1,0(s5)
    80004a0e:	028a2503          	lw	a0,40(s4)
    80004a12:	fffff097          	auipc	ra,0xfffff
    80004a16:	cb8080e7          	jalr	-840(ra) # 800036ca <bread>
    80004a1a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004a1c:	40000613          	li	a2,1024
    80004a20:	05850593          	addi	a1,a0,88
    80004a24:	05848513          	addi	a0,s1,88
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	436080e7          	jalr	1078(ra) # 80000e5e <memmove>
    bwrite(to);  // write the log
    80004a30:	8526                	mv	a0,s1
    80004a32:	fffff097          	auipc	ra,0xfffff
    80004a36:	d8a080e7          	jalr	-630(ra) # 800037bc <bwrite>
    brelse(from);
    80004a3a:	854e                	mv	a0,s3
    80004a3c:	fffff097          	auipc	ra,0xfffff
    80004a40:	dbe080e7          	jalr	-578(ra) # 800037fa <brelse>
    brelse(to);
    80004a44:	8526                	mv	a0,s1
    80004a46:	fffff097          	auipc	ra,0xfffff
    80004a4a:	db4080e7          	jalr	-588(ra) # 800037fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a4e:	2905                	addiw	s2,s2,1
    80004a50:	0a91                	addi	s5,s5,4
    80004a52:	02ca2783          	lw	a5,44(s4)
    80004a56:	f8f94ee3          	blt	s2,a5,800049f2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	c6a080e7          	jalr	-918(ra) # 800046c4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004a62:	4501                	li	a0,0
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	cda080e7          	jalr	-806(ra) # 8000473e <install_trans>
    log.lh.n = 0;
    80004a6c:	0023d797          	auipc	a5,0x23d
    80004a70:	b407a423          	sw	zero,-1208(a5) # 802415b4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004a74:	00000097          	auipc	ra,0x0
    80004a78:	c50080e7          	jalr	-944(ra) # 800046c4 <write_head>
    80004a7c:	bdf5                	j	80004978 <end_op+0x52>

0000000080004a7e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004a7e:	1101                	addi	sp,sp,-32
    80004a80:	ec06                	sd	ra,24(sp)
    80004a82:	e822                	sd	s0,16(sp)
    80004a84:	e426                	sd	s1,8(sp)
    80004a86:	e04a                	sd	s2,0(sp)
    80004a88:	1000                	addi	s0,sp,32
    80004a8a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a8c:	0023d917          	auipc	s2,0x23d
    80004a90:	afc90913          	addi	s2,s2,-1284 # 80241588 <log>
    80004a94:	854a                	mv	a0,s2
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	270080e7          	jalr	624(ra) # 80000d06 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a9e:	02c92603          	lw	a2,44(s2)
    80004aa2:	47f5                	li	a5,29
    80004aa4:	06c7c563          	blt	a5,a2,80004b0e <log_write+0x90>
    80004aa8:	0023d797          	auipc	a5,0x23d
    80004aac:	afc7a783          	lw	a5,-1284(a5) # 802415a4 <log+0x1c>
    80004ab0:	37fd                	addiw	a5,a5,-1
    80004ab2:	04f65e63          	bge	a2,a5,80004b0e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004ab6:	0023d797          	auipc	a5,0x23d
    80004aba:	af27a783          	lw	a5,-1294(a5) # 802415a8 <log+0x20>
    80004abe:	06f05063          	blez	a5,80004b1e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ac2:	4781                	li	a5,0
    80004ac4:	06c05563          	blez	a2,80004b2e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ac8:	44cc                	lw	a1,12(s1)
    80004aca:	0023d717          	auipc	a4,0x23d
    80004ace:	aee70713          	addi	a4,a4,-1298 # 802415b8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004ad2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004ad4:	4314                	lw	a3,0(a4)
    80004ad6:	04b68c63          	beq	a3,a1,80004b2e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004ada:	2785                	addiw	a5,a5,1
    80004adc:	0711                	addi	a4,a4,4
    80004ade:	fef61be3          	bne	a2,a5,80004ad4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004ae2:	0621                	addi	a2,a2,8
    80004ae4:	060a                	slli	a2,a2,0x2
    80004ae6:	0023d797          	auipc	a5,0x23d
    80004aea:	aa278793          	addi	a5,a5,-1374 # 80241588 <log>
    80004aee:	963e                	add	a2,a2,a5
    80004af0:	44dc                	lw	a5,12(s1)
    80004af2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004af4:	8526                	mv	a0,s1
    80004af6:	fffff097          	auipc	ra,0xfffff
    80004afa:	da2080e7          	jalr	-606(ra) # 80003898 <bpin>
    log.lh.n++;
    80004afe:	0023d717          	auipc	a4,0x23d
    80004b02:	a8a70713          	addi	a4,a4,-1398 # 80241588 <log>
    80004b06:	575c                	lw	a5,44(a4)
    80004b08:	2785                	addiw	a5,a5,1
    80004b0a:	d75c                	sw	a5,44(a4)
    80004b0c:	a835                	j	80004b48 <log_write+0xca>
    panic("too big a transaction");
    80004b0e:	00004517          	auipc	a0,0x4
    80004b12:	b9a50513          	addi	a0,a0,-1126 # 800086a8 <syscalls+0x220>
    80004b16:	ffffc097          	auipc	ra,0xffffc
    80004b1a:	a28080e7          	jalr	-1496(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    80004b1e:	00004517          	auipc	a0,0x4
    80004b22:	ba250513          	addi	a0,a0,-1118 # 800086c0 <syscalls+0x238>
    80004b26:	ffffc097          	auipc	ra,0xffffc
    80004b2a:	a18080e7          	jalr	-1512(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004b2e:	00878713          	addi	a4,a5,8
    80004b32:	00271693          	slli	a3,a4,0x2
    80004b36:	0023d717          	auipc	a4,0x23d
    80004b3a:	a5270713          	addi	a4,a4,-1454 # 80241588 <log>
    80004b3e:	9736                	add	a4,a4,a3
    80004b40:	44d4                	lw	a3,12(s1)
    80004b42:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004b44:	faf608e3          	beq	a2,a5,80004af4 <log_write+0x76>
  }
  release(&log.lock);
    80004b48:	0023d517          	auipc	a0,0x23d
    80004b4c:	a4050513          	addi	a0,a0,-1472 # 80241588 <log>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	26a080e7          	jalr	618(ra) # 80000dba <release>
}
    80004b58:	60e2                	ld	ra,24(sp)
    80004b5a:	6442                	ld	s0,16(sp)
    80004b5c:	64a2                	ld	s1,8(sp)
    80004b5e:	6902                	ld	s2,0(sp)
    80004b60:	6105                	addi	sp,sp,32
    80004b62:	8082                	ret

0000000080004b64 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004b64:	1101                	addi	sp,sp,-32
    80004b66:	ec06                	sd	ra,24(sp)
    80004b68:	e822                	sd	s0,16(sp)
    80004b6a:	e426                	sd	s1,8(sp)
    80004b6c:	e04a                	sd	s2,0(sp)
    80004b6e:	1000                	addi	s0,sp,32
    80004b70:	84aa                	mv	s1,a0
    80004b72:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004b74:	00004597          	auipc	a1,0x4
    80004b78:	b6c58593          	addi	a1,a1,-1172 # 800086e0 <syscalls+0x258>
    80004b7c:	0521                	addi	a0,a0,8
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	0f8080e7          	jalr	248(ra) # 80000c76 <initlock>
  lk->name = name;
    80004b86:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b8a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b8e:	0204a423          	sw	zero,40(s1)
}
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	64a2                	ld	s1,8(sp)
    80004b98:	6902                	ld	s2,0(sp)
    80004b9a:	6105                	addi	sp,sp,32
    80004b9c:	8082                	ret

0000000080004b9e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b9e:	1101                	addi	sp,sp,-32
    80004ba0:	ec06                	sd	ra,24(sp)
    80004ba2:	e822                	sd	s0,16(sp)
    80004ba4:	e426                	sd	s1,8(sp)
    80004ba6:	e04a                	sd	s2,0(sp)
    80004ba8:	1000                	addi	s0,sp,32
    80004baa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004bac:	00850913          	addi	s2,a0,8
    80004bb0:	854a                	mv	a0,s2
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	154080e7          	jalr	340(ra) # 80000d06 <acquire>
  while (lk->locked) {
    80004bba:	409c                	lw	a5,0(s1)
    80004bbc:	cb89                	beqz	a5,80004bce <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004bbe:	85ca                	mv	a1,s2
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffe097          	auipc	ra,0xffffe
    80004bc6:	8fc080e7          	jalr	-1796(ra) # 800024be <sleep>
  while (lk->locked) {
    80004bca:	409c                	lw	a5,0(s1)
    80004bcc:	fbed                	bnez	a5,80004bbe <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004bce:	4785                	li	a5,1
    80004bd0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004bd2:	ffffd097          	auipc	ra,0xffffd
    80004bd6:	fd2080e7          	jalr	-46(ra) # 80001ba4 <myproc>
    80004bda:	591c                	lw	a5,48(a0)
    80004bdc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004bde:	854a                	mv	a0,s2
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	1da080e7          	jalr	474(ra) # 80000dba <release>
}
    80004be8:	60e2                	ld	ra,24(sp)
    80004bea:	6442                	ld	s0,16(sp)
    80004bec:	64a2                	ld	s1,8(sp)
    80004bee:	6902                	ld	s2,0(sp)
    80004bf0:	6105                	addi	sp,sp,32
    80004bf2:	8082                	ret

0000000080004bf4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004bf4:	1101                	addi	sp,sp,-32
    80004bf6:	ec06                	sd	ra,24(sp)
    80004bf8:	e822                	sd	s0,16(sp)
    80004bfa:	e426                	sd	s1,8(sp)
    80004bfc:	e04a                	sd	s2,0(sp)
    80004bfe:	1000                	addi	s0,sp,32
    80004c00:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c02:	00850913          	addi	s2,a0,8
    80004c06:	854a                	mv	a0,s2
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	0fe080e7          	jalr	254(ra) # 80000d06 <acquire>
  lk->locked = 0;
    80004c10:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c14:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffe097          	auipc	ra,0xffffe
    80004c1e:	908080e7          	jalr	-1784(ra) # 80002522 <wakeup>
  release(&lk->lk);
    80004c22:	854a                	mv	a0,s2
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	196080e7          	jalr	406(ra) # 80000dba <release>
}
    80004c2c:	60e2                	ld	ra,24(sp)
    80004c2e:	6442                	ld	s0,16(sp)
    80004c30:	64a2                	ld	s1,8(sp)
    80004c32:	6902                	ld	s2,0(sp)
    80004c34:	6105                	addi	sp,sp,32
    80004c36:	8082                	ret

0000000080004c38 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004c38:	7179                	addi	sp,sp,-48
    80004c3a:	f406                	sd	ra,40(sp)
    80004c3c:	f022                	sd	s0,32(sp)
    80004c3e:	ec26                	sd	s1,24(sp)
    80004c40:	e84a                	sd	s2,16(sp)
    80004c42:	e44e                	sd	s3,8(sp)
    80004c44:	1800                	addi	s0,sp,48
    80004c46:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004c48:	00850913          	addi	s2,a0,8
    80004c4c:	854a                	mv	a0,s2
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	0b8080e7          	jalr	184(ra) # 80000d06 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c56:	409c                	lw	a5,0(s1)
    80004c58:	ef99                	bnez	a5,80004c76 <holdingsleep+0x3e>
    80004c5a:	4481                	li	s1,0
  release(&lk->lk);
    80004c5c:	854a                	mv	a0,s2
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	15c080e7          	jalr	348(ra) # 80000dba <release>
  return r;
}
    80004c66:	8526                	mv	a0,s1
    80004c68:	70a2                	ld	ra,40(sp)
    80004c6a:	7402                	ld	s0,32(sp)
    80004c6c:	64e2                	ld	s1,24(sp)
    80004c6e:	6942                	ld	s2,16(sp)
    80004c70:	69a2                	ld	s3,8(sp)
    80004c72:	6145                	addi	sp,sp,48
    80004c74:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004c76:	0284a983          	lw	s3,40(s1)
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	f2a080e7          	jalr	-214(ra) # 80001ba4 <myproc>
    80004c82:	5904                	lw	s1,48(a0)
    80004c84:	413484b3          	sub	s1,s1,s3
    80004c88:	0014b493          	seqz	s1,s1
    80004c8c:	bfc1                	j	80004c5c <holdingsleep+0x24>

0000000080004c8e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c8e:	1141                	addi	sp,sp,-16
    80004c90:	e406                	sd	ra,8(sp)
    80004c92:	e022                	sd	s0,0(sp)
    80004c94:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c96:	00004597          	auipc	a1,0x4
    80004c9a:	a5a58593          	addi	a1,a1,-1446 # 800086f0 <syscalls+0x268>
    80004c9e:	0023d517          	auipc	a0,0x23d
    80004ca2:	a3250513          	addi	a0,a0,-1486 # 802416d0 <ftable>
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	fd0080e7          	jalr	-48(ra) # 80000c76 <initlock>
}
    80004cae:	60a2                	ld	ra,8(sp)
    80004cb0:	6402                	ld	s0,0(sp)
    80004cb2:	0141                	addi	sp,sp,16
    80004cb4:	8082                	ret

0000000080004cb6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004cb6:	1101                	addi	sp,sp,-32
    80004cb8:	ec06                	sd	ra,24(sp)
    80004cba:	e822                	sd	s0,16(sp)
    80004cbc:	e426                	sd	s1,8(sp)
    80004cbe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004cc0:	0023d517          	auipc	a0,0x23d
    80004cc4:	a1050513          	addi	a0,a0,-1520 # 802416d0 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	03e080e7          	jalr	62(ra) # 80000d06 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004cd0:	0023d497          	auipc	s1,0x23d
    80004cd4:	a1848493          	addi	s1,s1,-1512 # 802416e8 <ftable+0x18>
    80004cd8:	0023e717          	auipc	a4,0x23e
    80004cdc:	9b070713          	addi	a4,a4,-1616 # 80242688 <disk>
    if(f->ref == 0){
    80004ce0:	40dc                	lw	a5,4(s1)
    80004ce2:	cf99                	beqz	a5,80004d00 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ce4:	02848493          	addi	s1,s1,40
    80004ce8:	fee49ce3          	bne	s1,a4,80004ce0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004cec:	0023d517          	auipc	a0,0x23d
    80004cf0:	9e450513          	addi	a0,a0,-1564 # 802416d0 <ftable>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	0c6080e7          	jalr	198(ra) # 80000dba <release>
  return 0;
    80004cfc:	4481                	li	s1,0
    80004cfe:	a819                	j	80004d14 <filealloc+0x5e>
      f->ref = 1;
    80004d00:	4785                	li	a5,1
    80004d02:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004d04:	0023d517          	auipc	a0,0x23d
    80004d08:	9cc50513          	addi	a0,a0,-1588 # 802416d0 <ftable>
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	0ae080e7          	jalr	174(ra) # 80000dba <release>
}
    80004d14:	8526                	mv	a0,s1
    80004d16:	60e2                	ld	ra,24(sp)
    80004d18:	6442                	ld	s0,16(sp)
    80004d1a:	64a2                	ld	s1,8(sp)
    80004d1c:	6105                	addi	sp,sp,32
    80004d1e:	8082                	ret

0000000080004d20 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004d20:	1101                	addi	sp,sp,-32
    80004d22:	ec06                	sd	ra,24(sp)
    80004d24:	e822                	sd	s0,16(sp)
    80004d26:	e426                	sd	s1,8(sp)
    80004d28:	1000                	addi	s0,sp,32
    80004d2a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004d2c:	0023d517          	auipc	a0,0x23d
    80004d30:	9a450513          	addi	a0,a0,-1628 # 802416d0 <ftable>
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	fd2080e7          	jalr	-46(ra) # 80000d06 <acquire>
  if(f->ref < 1)
    80004d3c:	40dc                	lw	a5,4(s1)
    80004d3e:	02f05263          	blez	a5,80004d62 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004d42:	2785                	addiw	a5,a5,1
    80004d44:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004d46:	0023d517          	auipc	a0,0x23d
    80004d4a:	98a50513          	addi	a0,a0,-1654 # 802416d0 <ftable>
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	06c080e7          	jalr	108(ra) # 80000dba <release>
  return f;
}
    80004d56:	8526                	mv	a0,s1
    80004d58:	60e2                	ld	ra,24(sp)
    80004d5a:	6442                	ld	s0,16(sp)
    80004d5c:	64a2                	ld	s1,8(sp)
    80004d5e:	6105                	addi	sp,sp,32
    80004d60:	8082                	ret
    panic("filedup");
    80004d62:	00004517          	auipc	a0,0x4
    80004d66:	99650513          	addi	a0,a0,-1642 # 800086f8 <syscalls+0x270>
    80004d6a:	ffffb097          	auipc	ra,0xffffb
    80004d6e:	7d4080e7          	jalr	2004(ra) # 8000053e <panic>

0000000080004d72 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004d72:	7139                	addi	sp,sp,-64
    80004d74:	fc06                	sd	ra,56(sp)
    80004d76:	f822                	sd	s0,48(sp)
    80004d78:	f426                	sd	s1,40(sp)
    80004d7a:	f04a                	sd	s2,32(sp)
    80004d7c:	ec4e                	sd	s3,24(sp)
    80004d7e:	e852                	sd	s4,16(sp)
    80004d80:	e456                	sd	s5,8(sp)
    80004d82:	0080                	addi	s0,sp,64
    80004d84:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004d86:	0023d517          	auipc	a0,0x23d
    80004d8a:	94a50513          	addi	a0,a0,-1718 # 802416d0 <ftable>
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	f78080e7          	jalr	-136(ra) # 80000d06 <acquire>
  if(f->ref < 1)
    80004d96:	40dc                	lw	a5,4(s1)
    80004d98:	06f05163          	blez	a5,80004dfa <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d9c:	37fd                	addiw	a5,a5,-1
    80004d9e:	0007871b          	sext.w	a4,a5
    80004da2:	c0dc                	sw	a5,4(s1)
    80004da4:	06e04363          	bgtz	a4,80004e0a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004da8:	0004a903          	lw	s2,0(s1)
    80004dac:	0094ca83          	lbu	s5,9(s1)
    80004db0:	0104ba03          	ld	s4,16(s1)
    80004db4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004db8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004dbc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004dc0:	0023d517          	auipc	a0,0x23d
    80004dc4:	91050513          	addi	a0,a0,-1776 # 802416d0 <ftable>
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	ff2080e7          	jalr	-14(ra) # 80000dba <release>

  if(ff.type == FD_PIPE){
    80004dd0:	4785                	li	a5,1
    80004dd2:	04f90d63          	beq	s2,a5,80004e2c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004dd6:	3979                	addiw	s2,s2,-2
    80004dd8:	4785                	li	a5,1
    80004dda:	0527e063          	bltu	a5,s2,80004e1a <fileclose+0xa8>
    begin_op();
    80004dde:	00000097          	auipc	ra,0x0
    80004de2:	ac8080e7          	jalr	-1336(ra) # 800048a6 <begin_op>
    iput(ff.ip);
    80004de6:	854e                	mv	a0,s3
    80004de8:	fffff097          	auipc	ra,0xfffff
    80004dec:	2b6080e7          	jalr	694(ra) # 8000409e <iput>
    end_op();
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	b36080e7          	jalr	-1226(ra) # 80004926 <end_op>
    80004df8:	a00d                	j	80004e1a <fileclose+0xa8>
    panic("fileclose");
    80004dfa:	00004517          	auipc	a0,0x4
    80004dfe:	90650513          	addi	a0,a0,-1786 # 80008700 <syscalls+0x278>
    80004e02:	ffffb097          	auipc	ra,0xffffb
    80004e06:	73c080e7          	jalr	1852(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004e0a:	0023d517          	auipc	a0,0x23d
    80004e0e:	8c650513          	addi	a0,a0,-1850 # 802416d0 <ftable>
    80004e12:	ffffc097          	auipc	ra,0xffffc
    80004e16:	fa8080e7          	jalr	-88(ra) # 80000dba <release>
  }
}
    80004e1a:	70e2                	ld	ra,56(sp)
    80004e1c:	7442                	ld	s0,48(sp)
    80004e1e:	74a2                	ld	s1,40(sp)
    80004e20:	7902                	ld	s2,32(sp)
    80004e22:	69e2                	ld	s3,24(sp)
    80004e24:	6a42                	ld	s4,16(sp)
    80004e26:	6aa2                	ld	s5,8(sp)
    80004e28:	6121                	addi	sp,sp,64
    80004e2a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004e2c:	85d6                	mv	a1,s5
    80004e2e:	8552                	mv	a0,s4
    80004e30:	00000097          	auipc	ra,0x0
    80004e34:	34c080e7          	jalr	844(ra) # 8000517c <pipeclose>
    80004e38:	b7cd                	j	80004e1a <fileclose+0xa8>

0000000080004e3a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004e3a:	715d                	addi	sp,sp,-80
    80004e3c:	e486                	sd	ra,72(sp)
    80004e3e:	e0a2                	sd	s0,64(sp)
    80004e40:	fc26                	sd	s1,56(sp)
    80004e42:	f84a                	sd	s2,48(sp)
    80004e44:	f44e                	sd	s3,40(sp)
    80004e46:	0880                	addi	s0,sp,80
    80004e48:	84aa                	mv	s1,a0
    80004e4a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	d58080e7          	jalr	-680(ra) # 80001ba4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004e54:	409c                	lw	a5,0(s1)
    80004e56:	37f9                	addiw	a5,a5,-2
    80004e58:	4705                	li	a4,1
    80004e5a:	04f76763          	bltu	a4,a5,80004ea8 <filestat+0x6e>
    80004e5e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004e60:	6c88                	ld	a0,24(s1)
    80004e62:	fffff097          	auipc	ra,0xfffff
    80004e66:	082080e7          	jalr	130(ra) # 80003ee4 <ilock>
    stati(f->ip, &st);
    80004e6a:	fb840593          	addi	a1,s0,-72
    80004e6e:	6c88                	ld	a0,24(s1)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	2fe080e7          	jalr	766(ra) # 8000416e <stati>
    iunlock(f->ip);
    80004e78:	6c88                	ld	a0,24(s1)
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	12c080e7          	jalr	300(ra) # 80003fa6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004e82:	46e1                	li	a3,24
    80004e84:	fb840613          	addi	a2,s0,-72
    80004e88:	85ce                	mv	a1,s3
    80004e8a:	05093503          	ld	a0,80(s2)
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	950080e7          	jalr	-1712(ra) # 800017de <copyout>
    80004e96:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e9a:	60a6                	ld	ra,72(sp)
    80004e9c:	6406                	ld	s0,64(sp)
    80004e9e:	74e2                	ld	s1,56(sp)
    80004ea0:	7942                	ld	s2,48(sp)
    80004ea2:	79a2                	ld	s3,40(sp)
    80004ea4:	6161                	addi	sp,sp,80
    80004ea6:	8082                	ret
  return -1;
    80004ea8:	557d                	li	a0,-1
    80004eaa:	bfc5                	j	80004e9a <filestat+0x60>

0000000080004eac <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004eac:	7179                	addi	sp,sp,-48
    80004eae:	f406                	sd	ra,40(sp)
    80004eb0:	f022                	sd	s0,32(sp)
    80004eb2:	ec26                	sd	s1,24(sp)
    80004eb4:	e84a                	sd	s2,16(sp)
    80004eb6:	e44e                	sd	s3,8(sp)
    80004eb8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004eba:	00854783          	lbu	a5,8(a0)
    80004ebe:	c3d5                	beqz	a5,80004f62 <fileread+0xb6>
    80004ec0:	84aa                	mv	s1,a0
    80004ec2:	89ae                	mv	s3,a1
    80004ec4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ec6:	411c                	lw	a5,0(a0)
    80004ec8:	4705                	li	a4,1
    80004eca:	04e78963          	beq	a5,a4,80004f1c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ece:	470d                	li	a4,3
    80004ed0:	04e78d63          	beq	a5,a4,80004f2a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ed4:	4709                	li	a4,2
    80004ed6:	06e79e63          	bne	a5,a4,80004f52 <fileread+0xa6>
    ilock(f->ip);
    80004eda:	6d08                	ld	a0,24(a0)
    80004edc:	fffff097          	auipc	ra,0xfffff
    80004ee0:	008080e7          	jalr	8(ra) # 80003ee4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ee4:	874a                	mv	a4,s2
    80004ee6:	5094                	lw	a3,32(s1)
    80004ee8:	864e                	mv	a2,s3
    80004eea:	4585                	li	a1,1
    80004eec:	6c88                	ld	a0,24(s1)
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	2aa080e7          	jalr	682(ra) # 80004198 <readi>
    80004ef6:	892a                	mv	s2,a0
    80004ef8:	00a05563          	blez	a0,80004f02 <fileread+0x56>
      f->off += r;
    80004efc:	509c                	lw	a5,32(s1)
    80004efe:	9fa9                	addw	a5,a5,a0
    80004f00:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f02:	6c88                	ld	a0,24(s1)
    80004f04:	fffff097          	auipc	ra,0xfffff
    80004f08:	0a2080e7          	jalr	162(ra) # 80003fa6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f0c:	854a                	mv	a0,s2
    80004f0e:	70a2                	ld	ra,40(sp)
    80004f10:	7402                	ld	s0,32(sp)
    80004f12:	64e2                	ld	s1,24(sp)
    80004f14:	6942                	ld	s2,16(sp)
    80004f16:	69a2                	ld	s3,8(sp)
    80004f18:	6145                	addi	sp,sp,48
    80004f1a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f1c:	6908                	ld	a0,16(a0)
    80004f1e:	00000097          	auipc	ra,0x0
    80004f22:	3c6080e7          	jalr	966(ra) # 800052e4 <piperead>
    80004f26:	892a                	mv	s2,a0
    80004f28:	b7d5                	j	80004f0c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f2a:	02451783          	lh	a5,36(a0)
    80004f2e:	03079693          	slli	a3,a5,0x30
    80004f32:	92c1                	srli	a3,a3,0x30
    80004f34:	4725                	li	a4,9
    80004f36:	02d76863          	bltu	a4,a3,80004f66 <fileread+0xba>
    80004f3a:	0792                	slli	a5,a5,0x4
    80004f3c:	0023c717          	auipc	a4,0x23c
    80004f40:	6f470713          	addi	a4,a4,1780 # 80241630 <devsw>
    80004f44:	97ba                	add	a5,a5,a4
    80004f46:	639c                	ld	a5,0(a5)
    80004f48:	c38d                	beqz	a5,80004f6a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f4a:	4505                	li	a0,1
    80004f4c:	9782                	jalr	a5
    80004f4e:	892a                	mv	s2,a0
    80004f50:	bf75                	j	80004f0c <fileread+0x60>
    panic("fileread");
    80004f52:	00003517          	auipc	a0,0x3
    80004f56:	7be50513          	addi	a0,a0,1982 # 80008710 <syscalls+0x288>
    80004f5a:	ffffb097          	auipc	ra,0xffffb
    80004f5e:	5e4080e7          	jalr	1508(ra) # 8000053e <panic>
    return -1;
    80004f62:	597d                	li	s2,-1
    80004f64:	b765                	j	80004f0c <fileread+0x60>
      return -1;
    80004f66:	597d                	li	s2,-1
    80004f68:	b755                	j	80004f0c <fileread+0x60>
    80004f6a:	597d                	li	s2,-1
    80004f6c:	b745                	j	80004f0c <fileread+0x60>

0000000080004f6e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004f6e:	715d                	addi	sp,sp,-80
    80004f70:	e486                	sd	ra,72(sp)
    80004f72:	e0a2                	sd	s0,64(sp)
    80004f74:	fc26                	sd	s1,56(sp)
    80004f76:	f84a                	sd	s2,48(sp)
    80004f78:	f44e                	sd	s3,40(sp)
    80004f7a:	f052                	sd	s4,32(sp)
    80004f7c:	ec56                	sd	s5,24(sp)
    80004f7e:	e85a                	sd	s6,16(sp)
    80004f80:	e45e                	sd	s7,8(sp)
    80004f82:	e062                	sd	s8,0(sp)
    80004f84:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f86:	00954783          	lbu	a5,9(a0)
    80004f8a:	10078663          	beqz	a5,80005096 <filewrite+0x128>
    80004f8e:	892a                	mv	s2,a0
    80004f90:	8aae                	mv	s5,a1
    80004f92:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f94:	411c                	lw	a5,0(a0)
    80004f96:	4705                	li	a4,1
    80004f98:	02e78263          	beq	a5,a4,80004fbc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f9c:	470d                	li	a4,3
    80004f9e:	02e78663          	beq	a5,a4,80004fca <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fa2:	4709                	li	a4,2
    80004fa4:	0ee79163          	bne	a5,a4,80005086 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fa8:	0ac05d63          	blez	a2,80005062 <filewrite+0xf4>
    int i = 0;
    80004fac:	4981                	li	s3,0
    80004fae:	6b05                	lui	s6,0x1
    80004fb0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fb4:	6b85                	lui	s7,0x1
    80004fb6:	c00b8b9b          	addiw	s7,s7,-1024
    80004fba:	a861                	j	80005052 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fbc:	6908                	ld	a0,16(a0)
    80004fbe:	00000097          	auipc	ra,0x0
    80004fc2:	22e080e7          	jalr	558(ra) # 800051ec <pipewrite>
    80004fc6:	8a2a                	mv	s4,a0
    80004fc8:	a045                	j	80005068 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fca:	02451783          	lh	a5,36(a0)
    80004fce:	03079693          	slli	a3,a5,0x30
    80004fd2:	92c1                	srli	a3,a3,0x30
    80004fd4:	4725                	li	a4,9
    80004fd6:	0cd76263          	bltu	a4,a3,8000509a <filewrite+0x12c>
    80004fda:	0792                	slli	a5,a5,0x4
    80004fdc:	0023c717          	auipc	a4,0x23c
    80004fe0:	65470713          	addi	a4,a4,1620 # 80241630 <devsw>
    80004fe4:	97ba                	add	a5,a5,a4
    80004fe6:	679c                	ld	a5,8(a5)
    80004fe8:	cbdd                	beqz	a5,8000509e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fea:	4505                	li	a0,1
    80004fec:	9782                	jalr	a5
    80004fee:	8a2a                	mv	s4,a0
    80004ff0:	a8a5                	j	80005068 <filewrite+0xfa>
    80004ff2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ff6:	00000097          	auipc	ra,0x0
    80004ffa:	8b0080e7          	jalr	-1872(ra) # 800048a6 <begin_op>
      ilock(f->ip);
    80004ffe:	01893503          	ld	a0,24(s2)
    80005002:	fffff097          	auipc	ra,0xfffff
    80005006:	ee2080e7          	jalr	-286(ra) # 80003ee4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000500a:	8762                	mv	a4,s8
    8000500c:	02092683          	lw	a3,32(s2)
    80005010:	01598633          	add	a2,s3,s5
    80005014:	4585                	li	a1,1
    80005016:	01893503          	ld	a0,24(s2)
    8000501a:	fffff097          	auipc	ra,0xfffff
    8000501e:	276080e7          	jalr	630(ra) # 80004290 <writei>
    80005022:	84aa                	mv	s1,a0
    80005024:	00a05763          	blez	a0,80005032 <filewrite+0xc4>
        f->off += r;
    80005028:	02092783          	lw	a5,32(s2)
    8000502c:	9fa9                	addw	a5,a5,a0
    8000502e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005032:	01893503          	ld	a0,24(s2)
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	f70080e7          	jalr	-144(ra) # 80003fa6 <iunlock>
      end_op();
    8000503e:	00000097          	auipc	ra,0x0
    80005042:	8e8080e7          	jalr	-1816(ra) # 80004926 <end_op>

      if(r != n1){
    80005046:	009c1f63          	bne	s8,s1,80005064 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000504a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000504e:	0149db63          	bge	s3,s4,80005064 <filewrite+0xf6>
      int n1 = n - i;
    80005052:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005056:	84be                	mv	s1,a5
    80005058:	2781                	sext.w	a5,a5
    8000505a:	f8fb5ce3          	bge	s6,a5,80004ff2 <filewrite+0x84>
    8000505e:	84de                	mv	s1,s7
    80005060:	bf49                	j	80004ff2 <filewrite+0x84>
    int i = 0;
    80005062:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005064:	013a1f63          	bne	s4,s3,80005082 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005068:	8552                	mv	a0,s4
    8000506a:	60a6                	ld	ra,72(sp)
    8000506c:	6406                	ld	s0,64(sp)
    8000506e:	74e2                	ld	s1,56(sp)
    80005070:	7942                	ld	s2,48(sp)
    80005072:	79a2                	ld	s3,40(sp)
    80005074:	7a02                	ld	s4,32(sp)
    80005076:	6ae2                	ld	s5,24(sp)
    80005078:	6b42                	ld	s6,16(sp)
    8000507a:	6ba2                	ld	s7,8(sp)
    8000507c:	6c02                	ld	s8,0(sp)
    8000507e:	6161                	addi	sp,sp,80
    80005080:	8082                	ret
    ret = (i == n ? n : -1);
    80005082:	5a7d                	li	s4,-1
    80005084:	b7d5                	j	80005068 <filewrite+0xfa>
    panic("filewrite");
    80005086:	00003517          	auipc	a0,0x3
    8000508a:	69a50513          	addi	a0,a0,1690 # 80008720 <syscalls+0x298>
    8000508e:	ffffb097          	auipc	ra,0xffffb
    80005092:	4b0080e7          	jalr	1200(ra) # 8000053e <panic>
    return -1;
    80005096:	5a7d                	li	s4,-1
    80005098:	bfc1                	j	80005068 <filewrite+0xfa>
      return -1;
    8000509a:	5a7d                	li	s4,-1
    8000509c:	b7f1                	j	80005068 <filewrite+0xfa>
    8000509e:	5a7d                	li	s4,-1
    800050a0:	b7e1                	j	80005068 <filewrite+0xfa>

00000000800050a2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050a2:	7179                	addi	sp,sp,-48
    800050a4:	f406                	sd	ra,40(sp)
    800050a6:	f022                	sd	s0,32(sp)
    800050a8:	ec26                	sd	s1,24(sp)
    800050aa:	e84a                	sd	s2,16(sp)
    800050ac:	e44e                	sd	s3,8(sp)
    800050ae:	e052                	sd	s4,0(sp)
    800050b0:	1800                	addi	s0,sp,48
    800050b2:	84aa                	mv	s1,a0
    800050b4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050b6:	0005b023          	sd	zero,0(a1)
    800050ba:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050be:	00000097          	auipc	ra,0x0
    800050c2:	bf8080e7          	jalr	-1032(ra) # 80004cb6 <filealloc>
    800050c6:	e088                	sd	a0,0(s1)
    800050c8:	c551                	beqz	a0,80005154 <pipealloc+0xb2>
    800050ca:	00000097          	auipc	ra,0x0
    800050ce:	bec080e7          	jalr	-1044(ra) # 80004cb6 <filealloc>
    800050d2:	00aa3023          	sd	a0,0(s4)
    800050d6:	c92d                	beqz	a0,80005148 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	b00080e7          	jalr	-1280(ra) # 80000bd8 <kalloc>
    800050e0:	892a                	mv	s2,a0
    800050e2:	c125                	beqz	a0,80005142 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050e4:	4985                	li	s3,1
    800050e6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050ea:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050ee:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050f2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050f6:	00003597          	auipc	a1,0x3
    800050fa:	63a58593          	addi	a1,a1,1594 # 80008730 <syscalls+0x2a8>
    800050fe:	ffffc097          	auipc	ra,0xffffc
    80005102:	b78080e7          	jalr	-1160(ra) # 80000c76 <initlock>
  (*f0)->type = FD_PIPE;
    80005106:	609c                	ld	a5,0(s1)
    80005108:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000510c:	609c                	ld	a5,0(s1)
    8000510e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005112:	609c                	ld	a5,0(s1)
    80005114:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005118:	609c                	ld	a5,0(s1)
    8000511a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000511e:	000a3783          	ld	a5,0(s4)
    80005122:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005126:	000a3783          	ld	a5,0(s4)
    8000512a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000512e:	000a3783          	ld	a5,0(s4)
    80005132:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005136:	000a3783          	ld	a5,0(s4)
    8000513a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000513e:	4501                	li	a0,0
    80005140:	a025                	j	80005168 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005142:	6088                	ld	a0,0(s1)
    80005144:	e501                	bnez	a0,8000514c <pipealloc+0xaa>
    80005146:	a039                	j	80005154 <pipealloc+0xb2>
    80005148:	6088                	ld	a0,0(s1)
    8000514a:	c51d                	beqz	a0,80005178 <pipealloc+0xd6>
    fileclose(*f0);
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	c26080e7          	jalr	-986(ra) # 80004d72 <fileclose>
  if(*f1)
    80005154:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005158:	557d                	li	a0,-1
  if(*f1)
    8000515a:	c799                	beqz	a5,80005168 <pipealloc+0xc6>
    fileclose(*f1);
    8000515c:	853e                	mv	a0,a5
    8000515e:	00000097          	auipc	ra,0x0
    80005162:	c14080e7          	jalr	-1004(ra) # 80004d72 <fileclose>
  return -1;
    80005166:	557d                	li	a0,-1
}
    80005168:	70a2                	ld	ra,40(sp)
    8000516a:	7402                	ld	s0,32(sp)
    8000516c:	64e2                	ld	s1,24(sp)
    8000516e:	6942                	ld	s2,16(sp)
    80005170:	69a2                	ld	s3,8(sp)
    80005172:	6a02                	ld	s4,0(sp)
    80005174:	6145                	addi	sp,sp,48
    80005176:	8082                	ret
  return -1;
    80005178:	557d                	li	a0,-1
    8000517a:	b7fd                	j	80005168 <pipealloc+0xc6>

000000008000517c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000517c:	1101                	addi	sp,sp,-32
    8000517e:	ec06                	sd	ra,24(sp)
    80005180:	e822                	sd	s0,16(sp)
    80005182:	e426                	sd	s1,8(sp)
    80005184:	e04a                	sd	s2,0(sp)
    80005186:	1000                	addi	s0,sp,32
    80005188:	84aa                	mv	s1,a0
    8000518a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	b7a080e7          	jalr	-1158(ra) # 80000d06 <acquire>
  if(writable){
    80005194:	02090d63          	beqz	s2,800051ce <pipeclose+0x52>
    pi->writeopen = 0;
    80005198:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000519c:	21848513          	addi	a0,s1,536
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	382080e7          	jalr	898(ra) # 80002522 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051a8:	2204b783          	ld	a5,544(s1)
    800051ac:	eb95                	bnez	a5,800051e0 <pipeclose+0x64>
    release(&pi->lock);
    800051ae:	8526                	mv	a0,s1
    800051b0:	ffffc097          	auipc	ra,0xffffc
    800051b4:	c0a080e7          	jalr	-1014(ra) # 80000dba <release>
    kfree((char*)pi);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	830080e7          	jalr	-2000(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800051c2:	60e2                	ld	ra,24(sp)
    800051c4:	6442                	ld	s0,16(sp)
    800051c6:	64a2                	ld	s1,8(sp)
    800051c8:	6902                	ld	s2,0(sp)
    800051ca:	6105                	addi	sp,sp,32
    800051cc:	8082                	ret
    pi->readopen = 0;
    800051ce:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051d2:	21c48513          	addi	a0,s1,540
    800051d6:	ffffd097          	auipc	ra,0xffffd
    800051da:	34c080e7          	jalr	844(ra) # 80002522 <wakeup>
    800051de:	b7e9                	j	800051a8 <pipeclose+0x2c>
    release(&pi->lock);
    800051e0:	8526                	mv	a0,s1
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	bd8080e7          	jalr	-1064(ra) # 80000dba <release>
}
    800051ea:	bfe1                	j	800051c2 <pipeclose+0x46>

00000000800051ec <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051ec:	711d                	addi	sp,sp,-96
    800051ee:	ec86                	sd	ra,88(sp)
    800051f0:	e8a2                	sd	s0,80(sp)
    800051f2:	e4a6                	sd	s1,72(sp)
    800051f4:	e0ca                	sd	s2,64(sp)
    800051f6:	fc4e                	sd	s3,56(sp)
    800051f8:	f852                	sd	s4,48(sp)
    800051fa:	f456                	sd	s5,40(sp)
    800051fc:	f05a                	sd	s6,32(sp)
    800051fe:	ec5e                	sd	s7,24(sp)
    80005200:	e862                	sd	s8,16(sp)
    80005202:	1080                	addi	s0,sp,96
    80005204:	84aa                	mv	s1,a0
    80005206:	8aae                	mv	s5,a1
    80005208:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	99a080e7          	jalr	-1638(ra) # 80001ba4 <myproc>
    80005212:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005214:	8526                	mv	a0,s1
    80005216:	ffffc097          	auipc	ra,0xffffc
    8000521a:	af0080e7          	jalr	-1296(ra) # 80000d06 <acquire>
  while(i < n){
    8000521e:	0b405663          	blez	s4,800052ca <pipewrite+0xde>
  int i = 0;
    80005222:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005224:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005226:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000522a:	21c48b93          	addi	s7,s1,540
    8000522e:	a089                	j	80005270 <pipewrite+0x84>
      release(&pi->lock);
    80005230:	8526                	mv	a0,s1
    80005232:	ffffc097          	auipc	ra,0xffffc
    80005236:	b88080e7          	jalr	-1144(ra) # 80000dba <release>
      return -1;
    8000523a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000523c:	854a                	mv	a0,s2
    8000523e:	60e6                	ld	ra,88(sp)
    80005240:	6446                	ld	s0,80(sp)
    80005242:	64a6                	ld	s1,72(sp)
    80005244:	6906                	ld	s2,64(sp)
    80005246:	79e2                	ld	s3,56(sp)
    80005248:	7a42                	ld	s4,48(sp)
    8000524a:	7aa2                	ld	s5,40(sp)
    8000524c:	7b02                	ld	s6,32(sp)
    8000524e:	6be2                	ld	s7,24(sp)
    80005250:	6c42                	ld	s8,16(sp)
    80005252:	6125                	addi	sp,sp,96
    80005254:	8082                	ret
      wakeup(&pi->nread);
    80005256:	8562                	mv	a0,s8
    80005258:	ffffd097          	auipc	ra,0xffffd
    8000525c:	2ca080e7          	jalr	714(ra) # 80002522 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005260:	85a6                	mv	a1,s1
    80005262:	855e                	mv	a0,s7
    80005264:	ffffd097          	auipc	ra,0xffffd
    80005268:	25a080e7          	jalr	602(ra) # 800024be <sleep>
  while(i < n){
    8000526c:	07495063          	bge	s2,s4,800052cc <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005270:	2204a783          	lw	a5,544(s1)
    80005274:	dfd5                	beqz	a5,80005230 <pipewrite+0x44>
    80005276:	854e                	mv	a0,s3
    80005278:	ffffd097          	auipc	ra,0xffffd
    8000527c:	4fa080e7          	jalr	1274(ra) # 80002772 <killed>
    80005280:	f945                	bnez	a0,80005230 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005282:	2184a783          	lw	a5,536(s1)
    80005286:	21c4a703          	lw	a4,540(s1)
    8000528a:	2007879b          	addiw	a5,a5,512
    8000528e:	fcf704e3          	beq	a4,a5,80005256 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005292:	4685                	li	a3,1
    80005294:	01590633          	add	a2,s2,s5
    80005298:	faf40593          	addi	a1,s0,-81
    8000529c:	0509b503          	ld	a0,80(s3)
    800052a0:	ffffc097          	auipc	ra,0xffffc
    800052a4:	64c080e7          	jalr	1612(ra) # 800018ec <copyin>
    800052a8:	03650263          	beq	a0,s6,800052cc <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052ac:	21c4a783          	lw	a5,540(s1)
    800052b0:	0017871b          	addiw	a4,a5,1
    800052b4:	20e4ae23          	sw	a4,540(s1)
    800052b8:	1ff7f793          	andi	a5,a5,511
    800052bc:	97a6                	add	a5,a5,s1
    800052be:	faf44703          	lbu	a4,-81(s0)
    800052c2:	00e78c23          	sb	a4,24(a5)
      i++;
    800052c6:	2905                	addiw	s2,s2,1
    800052c8:	b755                	j	8000526c <pipewrite+0x80>
  int i = 0;
    800052ca:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052cc:	21848513          	addi	a0,s1,536
    800052d0:	ffffd097          	auipc	ra,0xffffd
    800052d4:	252080e7          	jalr	594(ra) # 80002522 <wakeup>
  release(&pi->lock);
    800052d8:	8526                	mv	a0,s1
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	ae0080e7          	jalr	-1312(ra) # 80000dba <release>
  return i;
    800052e2:	bfa9                	j	8000523c <pipewrite+0x50>

00000000800052e4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052e4:	715d                	addi	sp,sp,-80
    800052e6:	e486                	sd	ra,72(sp)
    800052e8:	e0a2                	sd	s0,64(sp)
    800052ea:	fc26                	sd	s1,56(sp)
    800052ec:	f84a                	sd	s2,48(sp)
    800052ee:	f44e                	sd	s3,40(sp)
    800052f0:	f052                	sd	s4,32(sp)
    800052f2:	ec56                	sd	s5,24(sp)
    800052f4:	e85a                	sd	s6,16(sp)
    800052f6:	0880                	addi	s0,sp,80
    800052f8:	84aa                	mv	s1,a0
    800052fa:	892e                	mv	s2,a1
    800052fc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052fe:	ffffd097          	auipc	ra,0xffffd
    80005302:	8a6080e7          	jalr	-1882(ra) # 80001ba4 <myproc>
    80005306:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	9fc080e7          	jalr	-1540(ra) # 80000d06 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005312:	2184a703          	lw	a4,536(s1)
    80005316:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000531a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000531e:	02f71763          	bne	a4,a5,8000534c <piperead+0x68>
    80005322:	2244a783          	lw	a5,548(s1)
    80005326:	c39d                	beqz	a5,8000534c <piperead+0x68>
    if(killed(pr)){
    80005328:	8552                	mv	a0,s4
    8000532a:	ffffd097          	auipc	ra,0xffffd
    8000532e:	448080e7          	jalr	1096(ra) # 80002772 <killed>
    80005332:	e941                	bnez	a0,800053c2 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005334:	85a6                	mv	a1,s1
    80005336:	854e                	mv	a0,s3
    80005338:	ffffd097          	auipc	ra,0xffffd
    8000533c:	186080e7          	jalr	390(ra) # 800024be <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005340:	2184a703          	lw	a4,536(s1)
    80005344:	21c4a783          	lw	a5,540(s1)
    80005348:	fcf70de3          	beq	a4,a5,80005322 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000534c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000534e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005350:	05505363          	blez	s5,80005396 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005354:	2184a783          	lw	a5,536(s1)
    80005358:	21c4a703          	lw	a4,540(s1)
    8000535c:	02f70d63          	beq	a4,a5,80005396 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005360:	0017871b          	addiw	a4,a5,1
    80005364:	20e4ac23          	sw	a4,536(s1)
    80005368:	1ff7f793          	andi	a5,a5,511
    8000536c:	97a6                	add	a5,a5,s1
    8000536e:	0187c783          	lbu	a5,24(a5)
    80005372:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005376:	4685                	li	a3,1
    80005378:	fbf40613          	addi	a2,s0,-65
    8000537c:	85ca                	mv	a1,s2
    8000537e:	050a3503          	ld	a0,80(s4)
    80005382:	ffffc097          	auipc	ra,0xffffc
    80005386:	45c080e7          	jalr	1116(ra) # 800017de <copyout>
    8000538a:	01650663          	beq	a0,s6,80005396 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000538e:	2985                	addiw	s3,s3,1
    80005390:	0905                	addi	s2,s2,1
    80005392:	fd3a91e3          	bne	s5,s3,80005354 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005396:	21c48513          	addi	a0,s1,540
    8000539a:	ffffd097          	auipc	ra,0xffffd
    8000539e:	188080e7          	jalr	392(ra) # 80002522 <wakeup>
  release(&pi->lock);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffc097          	auipc	ra,0xffffc
    800053a8:	a16080e7          	jalr	-1514(ra) # 80000dba <release>
  return i;
}
    800053ac:	854e                	mv	a0,s3
    800053ae:	60a6                	ld	ra,72(sp)
    800053b0:	6406                	ld	s0,64(sp)
    800053b2:	74e2                	ld	s1,56(sp)
    800053b4:	7942                	ld	s2,48(sp)
    800053b6:	79a2                	ld	s3,40(sp)
    800053b8:	7a02                	ld	s4,32(sp)
    800053ba:	6ae2                	ld	s5,24(sp)
    800053bc:	6b42                	ld	s6,16(sp)
    800053be:	6161                	addi	sp,sp,80
    800053c0:	8082                	ret
      release(&pi->lock);
    800053c2:	8526                	mv	a0,s1
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	9f6080e7          	jalr	-1546(ra) # 80000dba <release>
      return -1;
    800053cc:	59fd                	li	s3,-1
    800053ce:	bff9                	j	800053ac <piperead+0xc8>

00000000800053d0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800053d0:	1141                	addi	sp,sp,-16
    800053d2:	e422                	sd	s0,8(sp)
    800053d4:	0800                	addi	s0,sp,16
    800053d6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800053d8:	8905                	andi	a0,a0,1
    800053da:	c111                	beqz	a0,800053de <flags2perm+0xe>
      perm = PTE_X;
    800053dc:	4521                	li	a0,8
    if(flags & 0x2)
    800053de:	8b89                	andi	a5,a5,2
    800053e0:	c399                	beqz	a5,800053e6 <flags2perm+0x16>
      perm |= PTE_W;
    800053e2:	00456513          	ori	a0,a0,4
    return perm;
}
    800053e6:	6422                	ld	s0,8(sp)
    800053e8:	0141                	addi	sp,sp,16
    800053ea:	8082                	ret

00000000800053ec <exec>:

int
exec(char *path, char **argv)
{
    800053ec:	de010113          	addi	sp,sp,-544
    800053f0:	20113c23          	sd	ra,536(sp)
    800053f4:	20813823          	sd	s0,528(sp)
    800053f8:	20913423          	sd	s1,520(sp)
    800053fc:	21213023          	sd	s2,512(sp)
    80005400:	ffce                	sd	s3,504(sp)
    80005402:	fbd2                	sd	s4,496(sp)
    80005404:	f7d6                	sd	s5,488(sp)
    80005406:	f3da                	sd	s6,480(sp)
    80005408:	efde                	sd	s7,472(sp)
    8000540a:	ebe2                	sd	s8,464(sp)
    8000540c:	e7e6                	sd	s9,456(sp)
    8000540e:	e3ea                	sd	s10,448(sp)
    80005410:	ff6e                	sd	s11,440(sp)
    80005412:	1400                	addi	s0,sp,544
    80005414:	892a                	mv	s2,a0
    80005416:	dea43423          	sd	a0,-536(s0)
    8000541a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	786080e7          	jalr	1926(ra) # 80001ba4 <myproc>
    80005426:	84aa                	mv	s1,a0

  begin_op();
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	47e080e7          	jalr	1150(ra) # 800048a6 <begin_op>

  if((ip = namei(path)) == 0){
    80005430:	854a                	mv	a0,s2
    80005432:	fffff097          	auipc	ra,0xfffff
    80005436:	258080e7          	jalr	600(ra) # 8000468a <namei>
    8000543a:	c93d                	beqz	a0,800054b0 <exec+0xc4>
    8000543c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	aa6080e7          	jalr	-1370(ra) # 80003ee4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005446:	04000713          	li	a4,64
    8000544a:	4681                	li	a3,0
    8000544c:	e5040613          	addi	a2,s0,-432
    80005450:	4581                	li	a1,0
    80005452:	8556                	mv	a0,s5
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	d44080e7          	jalr	-700(ra) # 80004198 <readi>
    8000545c:	04000793          	li	a5,64
    80005460:	00f51a63          	bne	a0,a5,80005474 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005464:	e5042703          	lw	a4,-432(s0)
    80005468:	464c47b7          	lui	a5,0x464c4
    8000546c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005470:	04f70663          	beq	a4,a5,800054bc <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005474:	8556                	mv	a0,s5
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	cd0080e7          	jalr	-816(ra) # 80004146 <iunlockput>
    end_op();
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	4a8080e7          	jalr	1192(ra) # 80004926 <end_op>
  }
  return -1;
    80005486:	557d                	li	a0,-1
}
    80005488:	21813083          	ld	ra,536(sp)
    8000548c:	21013403          	ld	s0,528(sp)
    80005490:	20813483          	ld	s1,520(sp)
    80005494:	20013903          	ld	s2,512(sp)
    80005498:	79fe                	ld	s3,504(sp)
    8000549a:	7a5e                	ld	s4,496(sp)
    8000549c:	7abe                	ld	s5,488(sp)
    8000549e:	7b1e                	ld	s6,480(sp)
    800054a0:	6bfe                	ld	s7,472(sp)
    800054a2:	6c5e                	ld	s8,464(sp)
    800054a4:	6cbe                	ld	s9,456(sp)
    800054a6:	6d1e                	ld	s10,448(sp)
    800054a8:	7dfa                	ld	s11,440(sp)
    800054aa:	22010113          	addi	sp,sp,544
    800054ae:	8082                	ret
    end_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	476080e7          	jalr	1142(ra) # 80004926 <end_op>
    return -1;
    800054b8:	557d                	li	a0,-1
    800054ba:	b7f9                	j	80005488 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800054bc:	8526                	mv	a0,s1
    800054be:	ffffc097          	auipc	ra,0xffffc
    800054c2:	7aa080e7          	jalr	1962(ra) # 80001c68 <proc_pagetable>
    800054c6:	8b2a                	mv	s6,a0
    800054c8:	d555                	beqz	a0,80005474 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ca:	e7042783          	lw	a5,-400(s0)
    800054ce:	e8845703          	lhu	a4,-376(s0)
    800054d2:	c735                	beqz	a4,8000553e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054d4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054d6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054da:	6a05                	lui	s4,0x1
    800054dc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054e0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800054e4:	6d85                	lui	s11,0x1
    800054e6:	7d7d                	lui	s10,0xfffff
    800054e8:	a481                	j	80005728 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054ea:	00003517          	auipc	a0,0x3
    800054ee:	24e50513          	addi	a0,a0,590 # 80008738 <syscalls+0x2b0>
    800054f2:	ffffb097          	auipc	ra,0xffffb
    800054f6:	04c080e7          	jalr	76(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054fa:	874a                	mv	a4,s2
    800054fc:	009c86bb          	addw	a3,s9,s1
    80005500:	4581                	li	a1,0
    80005502:	8556                	mv	a0,s5
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	c94080e7          	jalr	-876(ra) # 80004198 <readi>
    8000550c:	2501                	sext.w	a0,a0
    8000550e:	1aa91a63          	bne	s2,a0,800056c2 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    80005512:	009d84bb          	addw	s1,s11,s1
    80005516:	013d09bb          	addw	s3,s10,s3
    8000551a:	1f74f763          	bgeu	s1,s7,80005708 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    8000551e:	02049593          	slli	a1,s1,0x20
    80005522:	9181                	srli	a1,a1,0x20
    80005524:	95e2                	add	a1,a1,s8
    80005526:	855a                	mv	a0,s6
    80005528:	ffffc097          	auipc	ra,0xffffc
    8000552c:	c64080e7          	jalr	-924(ra) # 8000118c <walkaddr>
    80005530:	862a                	mv	a2,a0
    if(pa == 0)
    80005532:	dd45                	beqz	a0,800054ea <exec+0xfe>
      n = PGSIZE;
    80005534:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005536:	fd49f2e3          	bgeu	s3,s4,800054fa <exec+0x10e>
      n = sz - i;
    8000553a:	894e                	mv	s2,s3
    8000553c:	bf7d                	j	800054fa <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000553e:	4901                	li	s2,0
  iunlockput(ip);
    80005540:	8556                	mv	a0,s5
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	c04080e7          	jalr	-1020(ra) # 80004146 <iunlockput>
  end_op();
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	3dc080e7          	jalr	988(ra) # 80004926 <end_op>
  p = myproc();
    80005552:	ffffc097          	auipc	ra,0xffffc
    80005556:	652080e7          	jalr	1618(ra) # 80001ba4 <myproc>
    8000555a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000555c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005560:	6785                	lui	a5,0x1
    80005562:	17fd                	addi	a5,a5,-1
    80005564:	993e                	add	s2,s2,a5
    80005566:	77fd                	lui	a5,0xfffff
    80005568:	00f977b3          	and	a5,s2,a5
    8000556c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005570:	4691                	li	a3,4
    80005572:	6609                	lui	a2,0x2
    80005574:	963e                	add	a2,a2,a5
    80005576:	85be                	mv	a1,a5
    80005578:	855a                	mv	a0,s6
    8000557a:	ffffc097          	auipc	ra,0xffffc
    8000557e:	fc6080e7          	jalr	-58(ra) # 80001540 <uvmalloc>
    80005582:	8c2a                	mv	s8,a0
  ip = 0;
    80005584:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005586:	12050e63          	beqz	a0,800056c2 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000558a:	75f9                	lui	a1,0xffffe
    8000558c:	95aa                	add	a1,a1,a0
    8000558e:	855a                	mv	a0,s6
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	21c080e7          	jalr	540(ra) # 800017ac <uvmclear>
  stackbase = sp - PGSIZE;
    80005598:	7afd                	lui	s5,0xfffff
    8000559a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000559c:	df043783          	ld	a5,-528(s0)
    800055a0:	6388                	ld	a0,0(a5)
    800055a2:	c925                	beqz	a0,80005612 <exec+0x226>
    800055a4:	e9040993          	addi	s3,s0,-368
    800055a8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800055ac:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055ae:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800055b0:	ffffc097          	auipc	ra,0xffffc
    800055b4:	9ce080e7          	jalr	-1586(ra) # 80000f7e <strlen>
    800055b8:	0015079b          	addiw	a5,a0,1
    800055bc:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055c0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055c4:	13596663          	bltu	s2,s5,800056f0 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055c8:	df043d83          	ld	s11,-528(s0)
    800055cc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800055d0:	8552                	mv	a0,s4
    800055d2:	ffffc097          	auipc	ra,0xffffc
    800055d6:	9ac080e7          	jalr	-1620(ra) # 80000f7e <strlen>
    800055da:	0015069b          	addiw	a3,a0,1
    800055de:	8652                	mv	a2,s4
    800055e0:	85ca                	mv	a1,s2
    800055e2:	855a                	mv	a0,s6
    800055e4:	ffffc097          	auipc	ra,0xffffc
    800055e8:	1fa080e7          	jalr	506(ra) # 800017de <copyout>
    800055ec:	10054663          	bltz	a0,800056f8 <exec+0x30c>
    ustack[argc] = sp;
    800055f0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055f4:	0485                	addi	s1,s1,1
    800055f6:	008d8793          	addi	a5,s11,8
    800055fa:	def43823          	sd	a5,-528(s0)
    800055fe:	008db503          	ld	a0,8(s11)
    80005602:	c911                	beqz	a0,80005616 <exec+0x22a>
    if(argc >= MAXARG)
    80005604:	09a1                	addi	s3,s3,8
    80005606:	fb3c95e3          	bne	s9,s3,800055b0 <exec+0x1c4>
  sz = sz1;
    8000560a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000560e:	4a81                	li	s5,0
    80005610:	a84d                	j	800056c2 <exec+0x2d6>
  sp = sz;
    80005612:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005614:	4481                	li	s1,0
  ustack[argc] = 0;
    80005616:	00349793          	slli	a5,s1,0x3
    8000561a:	f9040713          	addi	a4,s0,-112
    8000561e:	97ba                	add	a5,a5,a4
    80005620:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7fdbc738>
  sp -= (argc+1) * sizeof(uint64);
    80005624:	00148693          	addi	a3,s1,1
    80005628:	068e                	slli	a3,a3,0x3
    8000562a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000562e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005632:	01597663          	bgeu	s2,s5,8000563e <exec+0x252>
  sz = sz1;
    80005636:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000563a:	4a81                	li	s5,0
    8000563c:	a059                	j	800056c2 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000563e:	e9040613          	addi	a2,s0,-368
    80005642:	85ca                	mv	a1,s2
    80005644:	855a                	mv	a0,s6
    80005646:	ffffc097          	auipc	ra,0xffffc
    8000564a:	198080e7          	jalr	408(ra) # 800017de <copyout>
    8000564e:	0a054963          	bltz	a0,80005700 <exec+0x314>
  p->trapframe->a1 = sp;
    80005652:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005656:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000565a:	de843783          	ld	a5,-536(s0)
    8000565e:	0007c703          	lbu	a4,0(a5)
    80005662:	cf11                	beqz	a4,8000567e <exec+0x292>
    80005664:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005666:	02f00693          	li	a3,47
    8000566a:	a039                	j	80005678 <exec+0x28c>
      last = s+1;
    8000566c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005670:	0785                	addi	a5,a5,1
    80005672:	fff7c703          	lbu	a4,-1(a5)
    80005676:	c701                	beqz	a4,8000567e <exec+0x292>
    if(*s == '/')
    80005678:	fed71ce3          	bne	a4,a3,80005670 <exec+0x284>
    8000567c:	bfc5                	j	8000566c <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    8000567e:	4641                	li	a2,16
    80005680:	de843583          	ld	a1,-536(s0)
    80005684:	158b8513          	addi	a0,s7,344
    80005688:	ffffc097          	auipc	ra,0xffffc
    8000568c:	8c4080e7          	jalr	-1852(ra) # 80000f4c <safestrcpy>
  oldpagetable = p->pagetable;
    80005690:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005694:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005698:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000569c:	058bb783          	ld	a5,88(s7)
    800056a0:	e6843703          	ld	a4,-408(s0)
    800056a4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800056a6:	058bb783          	ld	a5,88(s7)
    800056aa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800056ae:	85ea                	mv	a1,s10
    800056b0:	ffffc097          	auipc	ra,0xffffc
    800056b4:	654080e7          	jalr	1620(ra) # 80001d04 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056b8:	0004851b          	sext.w	a0,s1
    800056bc:	b3f1                	j	80005488 <exec+0x9c>
    800056be:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800056c2:	df843583          	ld	a1,-520(s0)
    800056c6:	855a                	mv	a0,s6
    800056c8:	ffffc097          	auipc	ra,0xffffc
    800056cc:	63c080e7          	jalr	1596(ra) # 80001d04 <proc_freepagetable>
  if(ip){
    800056d0:	da0a92e3          	bnez	s5,80005474 <exec+0x88>
  return -1;
    800056d4:	557d                	li	a0,-1
    800056d6:	bb4d                	j	80005488 <exec+0x9c>
    800056d8:	df243c23          	sd	s2,-520(s0)
    800056dc:	b7dd                	j	800056c2 <exec+0x2d6>
    800056de:	df243c23          	sd	s2,-520(s0)
    800056e2:	b7c5                	j	800056c2 <exec+0x2d6>
    800056e4:	df243c23          	sd	s2,-520(s0)
    800056e8:	bfe9                	j	800056c2 <exec+0x2d6>
    800056ea:	df243c23          	sd	s2,-520(s0)
    800056ee:	bfd1                	j	800056c2 <exec+0x2d6>
  sz = sz1;
    800056f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056f4:	4a81                	li	s5,0
    800056f6:	b7f1                	j	800056c2 <exec+0x2d6>
  sz = sz1;
    800056f8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056fc:	4a81                	li	s5,0
    800056fe:	b7d1                	j	800056c2 <exec+0x2d6>
  sz = sz1;
    80005700:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005704:	4a81                	li	s5,0
    80005706:	bf75                	j	800056c2 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005708:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000570c:	e0843783          	ld	a5,-504(s0)
    80005710:	0017869b          	addiw	a3,a5,1
    80005714:	e0d43423          	sd	a3,-504(s0)
    80005718:	e0043783          	ld	a5,-512(s0)
    8000571c:	0387879b          	addiw	a5,a5,56
    80005720:	e8845703          	lhu	a4,-376(s0)
    80005724:	e0e6dee3          	bge	a3,a4,80005540 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005728:	2781                	sext.w	a5,a5
    8000572a:	e0f43023          	sd	a5,-512(s0)
    8000572e:	03800713          	li	a4,56
    80005732:	86be                	mv	a3,a5
    80005734:	e1840613          	addi	a2,s0,-488
    80005738:	4581                	li	a1,0
    8000573a:	8556                	mv	a0,s5
    8000573c:	fffff097          	auipc	ra,0xfffff
    80005740:	a5c080e7          	jalr	-1444(ra) # 80004198 <readi>
    80005744:	03800793          	li	a5,56
    80005748:	f6f51be3          	bne	a0,a5,800056be <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000574c:	e1842783          	lw	a5,-488(s0)
    80005750:	4705                	li	a4,1
    80005752:	fae79de3          	bne	a5,a4,8000570c <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005756:	e4043483          	ld	s1,-448(s0)
    8000575a:	e3843783          	ld	a5,-456(s0)
    8000575e:	f6f4ede3          	bltu	s1,a5,800056d8 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005762:	e2843783          	ld	a5,-472(s0)
    80005766:	94be                	add	s1,s1,a5
    80005768:	f6f4ebe3          	bltu	s1,a5,800056de <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000576c:	de043703          	ld	a4,-544(s0)
    80005770:	8ff9                	and	a5,a5,a4
    80005772:	fbad                	bnez	a5,800056e4 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005774:	e1c42503          	lw	a0,-484(s0)
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	c58080e7          	jalr	-936(ra) # 800053d0 <flags2perm>
    80005780:	86aa                	mv	a3,a0
    80005782:	8626                	mv	a2,s1
    80005784:	85ca                	mv	a1,s2
    80005786:	855a                	mv	a0,s6
    80005788:	ffffc097          	auipc	ra,0xffffc
    8000578c:	db8080e7          	jalr	-584(ra) # 80001540 <uvmalloc>
    80005790:	dea43c23          	sd	a0,-520(s0)
    80005794:	d939                	beqz	a0,800056ea <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005796:	e2843c03          	ld	s8,-472(s0)
    8000579a:	e2042c83          	lw	s9,-480(s0)
    8000579e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800057a2:	f60b83e3          	beqz	s7,80005708 <exec+0x31c>
    800057a6:	89de                	mv	s3,s7
    800057a8:	4481                	li	s1,0
    800057aa:	bb95                	j	8000551e <exec+0x132>

00000000800057ac <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800057ac:	7179                	addi	sp,sp,-48
    800057ae:	f406                	sd	ra,40(sp)
    800057b0:	f022                	sd	s0,32(sp)
    800057b2:	ec26                	sd	s1,24(sp)
    800057b4:	e84a                	sd	s2,16(sp)
    800057b6:	1800                	addi	s0,sp,48
    800057b8:	892e                	mv	s2,a1
    800057ba:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800057bc:	fdc40593          	addi	a1,s0,-36
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	ac0080e7          	jalr	-1344(ra) # 80003280 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057c8:	fdc42703          	lw	a4,-36(s0)
    800057cc:	47bd                	li	a5,15
    800057ce:	02e7eb63          	bltu	a5,a4,80005804 <argfd+0x58>
    800057d2:	ffffc097          	auipc	ra,0xffffc
    800057d6:	3d2080e7          	jalr	978(ra) # 80001ba4 <myproc>
    800057da:	fdc42703          	lw	a4,-36(s0)
    800057de:	01a70793          	addi	a5,a4,26
    800057e2:	078e                	slli	a5,a5,0x3
    800057e4:	953e                	add	a0,a0,a5
    800057e6:	611c                	ld	a5,0(a0)
    800057e8:	c385                	beqz	a5,80005808 <argfd+0x5c>
    return -1;
  if(pfd)
    800057ea:	00090463          	beqz	s2,800057f2 <argfd+0x46>
    *pfd = fd;
    800057ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057f2:	4501                	li	a0,0
  if(pf)
    800057f4:	c091                	beqz	s1,800057f8 <argfd+0x4c>
    *pf = f;
    800057f6:	e09c                	sd	a5,0(s1)
}
    800057f8:	70a2                	ld	ra,40(sp)
    800057fa:	7402                	ld	s0,32(sp)
    800057fc:	64e2                	ld	s1,24(sp)
    800057fe:	6942                	ld	s2,16(sp)
    80005800:	6145                	addi	sp,sp,48
    80005802:	8082                	ret
    return -1;
    80005804:	557d                	li	a0,-1
    80005806:	bfcd                	j	800057f8 <argfd+0x4c>
    80005808:	557d                	li	a0,-1
    8000580a:	b7fd                	j	800057f8 <argfd+0x4c>

000000008000580c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000580c:	1101                	addi	sp,sp,-32
    8000580e:	ec06                	sd	ra,24(sp)
    80005810:	e822                	sd	s0,16(sp)
    80005812:	e426                	sd	s1,8(sp)
    80005814:	1000                	addi	s0,sp,32
    80005816:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005818:	ffffc097          	auipc	ra,0xffffc
    8000581c:	38c080e7          	jalr	908(ra) # 80001ba4 <myproc>
    80005820:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005822:	0d050793          	addi	a5,a0,208
    80005826:	4501                	li	a0,0
    80005828:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000582a:	6398                	ld	a4,0(a5)
    8000582c:	cb19                	beqz	a4,80005842 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000582e:	2505                	addiw	a0,a0,1
    80005830:	07a1                	addi	a5,a5,8
    80005832:	fed51ce3          	bne	a0,a3,8000582a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005836:	557d                	li	a0,-1
}
    80005838:	60e2                	ld	ra,24(sp)
    8000583a:	6442                	ld	s0,16(sp)
    8000583c:	64a2                	ld	s1,8(sp)
    8000583e:	6105                	addi	sp,sp,32
    80005840:	8082                	ret
      p->ofile[fd] = f;
    80005842:	01a50793          	addi	a5,a0,26
    80005846:	078e                	slli	a5,a5,0x3
    80005848:	963e                	add	a2,a2,a5
    8000584a:	e204                	sd	s1,0(a2)
      return fd;
    8000584c:	b7f5                	j	80005838 <fdalloc+0x2c>

000000008000584e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000584e:	715d                	addi	sp,sp,-80
    80005850:	e486                	sd	ra,72(sp)
    80005852:	e0a2                	sd	s0,64(sp)
    80005854:	fc26                	sd	s1,56(sp)
    80005856:	f84a                	sd	s2,48(sp)
    80005858:	f44e                	sd	s3,40(sp)
    8000585a:	f052                	sd	s4,32(sp)
    8000585c:	ec56                	sd	s5,24(sp)
    8000585e:	e85a                	sd	s6,16(sp)
    80005860:	0880                	addi	s0,sp,80
    80005862:	8b2e                	mv	s6,a1
    80005864:	89b2                	mv	s3,a2
    80005866:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005868:	fb040593          	addi	a1,s0,-80
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	e3c080e7          	jalr	-452(ra) # 800046a8 <nameiparent>
    80005874:	84aa                	mv	s1,a0
    80005876:	14050f63          	beqz	a0,800059d4 <create+0x186>
    return 0;

  ilock(dp);
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	66a080e7          	jalr	1642(ra) # 80003ee4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005882:	4601                	li	a2,0
    80005884:	fb040593          	addi	a1,s0,-80
    80005888:	8526                	mv	a0,s1
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	b3e080e7          	jalr	-1218(ra) # 800043c8 <dirlookup>
    80005892:	8aaa                	mv	s5,a0
    80005894:	c931                	beqz	a0,800058e8 <create+0x9a>
    iunlockput(dp);
    80005896:	8526                	mv	a0,s1
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	8ae080e7          	jalr	-1874(ra) # 80004146 <iunlockput>
    ilock(ip);
    800058a0:	8556                	mv	a0,s5
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	642080e7          	jalr	1602(ra) # 80003ee4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800058aa:	000b059b          	sext.w	a1,s6
    800058ae:	4789                	li	a5,2
    800058b0:	02f59563          	bne	a1,a5,800058da <create+0x8c>
    800058b4:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7fdbc87c>
    800058b8:	37f9                	addiw	a5,a5,-2
    800058ba:	17c2                	slli	a5,a5,0x30
    800058bc:	93c1                	srli	a5,a5,0x30
    800058be:	4705                	li	a4,1
    800058c0:	00f76d63          	bltu	a4,a5,800058da <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800058c4:	8556                	mv	a0,s5
    800058c6:	60a6                	ld	ra,72(sp)
    800058c8:	6406                	ld	s0,64(sp)
    800058ca:	74e2                	ld	s1,56(sp)
    800058cc:	7942                	ld	s2,48(sp)
    800058ce:	79a2                	ld	s3,40(sp)
    800058d0:	7a02                	ld	s4,32(sp)
    800058d2:	6ae2                	ld	s5,24(sp)
    800058d4:	6b42                	ld	s6,16(sp)
    800058d6:	6161                	addi	sp,sp,80
    800058d8:	8082                	ret
    iunlockput(ip);
    800058da:	8556                	mv	a0,s5
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	86a080e7          	jalr	-1942(ra) # 80004146 <iunlockput>
    return 0;
    800058e4:	4a81                	li	s5,0
    800058e6:	bff9                	j	800058c4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800058e8:	85da                	mv	a1,s6
    800058ea:	4088                	lw	a0,0(s1)
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	45c080e7          	jalr	1116(ra) # 80003d48 <ialloc>
    800058f4:	8a2a                	mv	s4,a0
    800058f6:	c539                	beqz	a0,80005944 <create+0xf6>
  ilock(ip);
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	5ec080e7          	jalr	1516(ra) # 80003ee4 <ilock>
  ip->major = major;
    80005900:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005904:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005908:	4905                	li	s2,1
    8000590a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000590e:	8552                	mv	a0,s4
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	50a080e7          	jalr	1290(ra) # 80003e1a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005918:	000b059b          	sext.w	a1,s6
    8000591c:	03258b63          	beq	a1,s2,80005952 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005920:	004a2603          	lw	a2,4(s4)
    80005924:	fb040593          	addi	a1,s0,-80
    80005928:	8526                	mv	a0,s1
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	cae080e7          	jalr	-850(ra) # 800045d8 <dirlink>
    80005932:	06054f63          	bltz	a0,800059b0 <create+0x162>
  iunlockput(dp);
    80005936:	8526                	mv	a0,s1
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	80e080e7          	jalr	-2034(ra) # 80004146 <iunlockput>
  return ip;
    80005940:	8ad2                	mv	s5,s4
    80005942:	b749                	j	800058c4 <create+0x76>
    iunlockput(dp);
    80005944:	8526                	mv	a0,s1
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	800080e7          	jalr	-2048(ra) # 80004146 <iunlockput>
    return 0;
    8000594e:	8ad2                	mv	s5,s4
    80005950:	bf95                	j	800058c4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005952:	004a2603          	lw	a2,4(s4)
    80005956:	00003597          	auipc	a1,0x3
    8000595a:	e0258593          	addi	a1,a1,-510 # 80008758 <syscalls+0x2d0>
    8000595e:	8552                	mv	a0,s4
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	c78080e7          	jalr	-904(ra) # 800045d8 <dirlink>
    80005968:	04054463          	bltz	a0,800059b0 <create+0x162>
    8000596c:	40d0                	lw	a2,4(s1)
    8000596e:	00003597          	auipc	a1,0x3
    80005972:	df258593          	addi	a1,a1,-526 # 80008760 <syscalls+0x2d8>
    80005976:	8552                	mv	a0,s4
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	c60080e7          	jalr	-928(ra) # 800045d8 <dirlink>
    80005980:	02054863          	bltz	a0,800059b0 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005984:	004a2603          	lw	a2,4(s4)
    80005988:	fb040593          	addi	a1,s0,-80
    8000598c:	8526                	mv	a0,s1
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	c4a080e7          	jalr	-950(ra) # 800045d8 <dirlink>
    80005996:	00054d63          	bltz	a0,800059b0 <create+0x162>
    dp->nlink++;  // for ".."
    8000599a:	04a4d783          	lhu	a5,74(s1)
    8000599e:	2785                	addiw	a5,a5,1
    800059a0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800059a4:	8526                	mv	a0,s1
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	474080e7          	jalr	1140(ra) # 80003e1a <iupdate>
    800059ae:	b761                	j	80005936 <create+0xe8>
  ip->nlink = 0;
    800059b0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800059b4:	8552                	mv	a0,s4
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	464080e7          	jalr	1124(ra) # 80003e1a <iupdate>
  iunlockput(ip);
    800059be:	8552                	mv	a0,s4
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	786080e7          	jalr	1926(ra) # 80004146 <iunlockput>
  iunlockput(dp);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	77c080e7          	jalr	1916(ra) # 80004146 <iunlockput>
  return 0;
    800059d2:	bdcd                	j	800058c4 <create+0x76>
    return 0;
    800059d4:	8aaa                	mv	s5,a0
    800059d6:	b5fd                	j	800058c4 <create+0x76>

00000000800059d8 <sys_dup>:
{
    800059d8:	7179                	addi	sp,sp,-48
    800059da:	f406                	sd	ra,40(sp)
    800059dc:	f022                	sd	s0,32(sp)
    800059de:	ec26                	sd	s1,24(sp)
    800059e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800059e2:	fd840613          	addi	a2,s0,-40
    800059e6:	4581                	li	a1,0
    800059e8:	4501                	li	a0,0
    800059ea:	00000097          	auipc	ra,0x0
    800059ee:	dc2080e7          	jalr	-574(ra) # 800057ac <argfd>
    return -1;
    800059f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800059f4:	02054363          	bltz	a0,80005a1a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800059f8:	fd843503          	ld	a0,-40(s0)
    800059fc:	00000097          	auipc	ra,0x0
    80005a00:	e10080e7          	jalr	-496(ra) # 8000580c <fdalloc>
    80005a04:	84aa                	mv	s1,a0
    return -1;
    80005a06:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a08:	00054963          	bltz	a0,80005a1a <sys_dup+0x42>
  filedup(f);
    80005a0c:	fd843503          	ld	a0,-40(s0)
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	310080e7          	jalr	784(ra) # 80004d20 <filedup>
  return fd;
    80005a18:	87a6                	mv	a5,s1
}
    80005a1a:	853e                	mv	a0,a5
    80005a1c:	70a2                	ld	ra,40(sp)
    80005a1e:	7402                	ld	s0,32(sp)
    80005a20:	64e2                	ld	s1,24(sp)
    80005a22:	6145                	addi	sp,sp,48
    80005a24:	8082                	ret

0000000080005a26 <sys_getreadcount>:
{
    80005a26:	1141                	addi	sp,sp,-16
    80005a28:	e422                	sd	s0,8(sp)
    80005a2a:	0800                	addi	s0,sp,16
}
    80005a2c:	00003517          	auipc	a0,0x3
    80005a30:	f0852503          	lw	a0,-248(a0) # 80008934 <readCount>
    80005a34:	6422                	ld	s0,8(sp)
    80005a36:	0141                	addi	sp,sp,16
    80005a38:	8082                	ret

0000000080005a3a <sys_read>:
{
    80005a3a:	7179                	addi	sp,sp,-48
    80005a3c:	f406                	sd	ra,40(sp)
    80005a3e:	f022                	sd	s0,32(sp)
    80005a40:	1800                	addi	s0,sp,48
  readCount++;
    80005a42:	00003717          	auipc	a4,0x3
    80005a46:	ef270713          	addi	a4,a4,-270 # 80008934 <readCount>
    80005a4a:	431c                	lw	a5,0(a4)
    80005a4c:	2785                	addiw	a5,a5,1
    80005a4e:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005a50:	fd840593          	addi	a1,s0,-40
    80005a54:	4505                	li	a0,1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	84a080e7          	jalr	-1974(ra) # 800032a0 <argaddr>
  argint(2, &n);
    80005a5e:	fe440593          	addi	a1,s0,-28
    80005a62:	4509                	li	a0,2
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	81c080e7          	jalr	-2020(ra) # 80003280 <argint>
  if(argfd(0, 0, &f) < 0)
    80005a6c:	fe840613          	addi	a2,s0,-24
    80005a70:	4581                	li	a1,0
    80005a72:	4501                	li	a0,0
    80005a74:	00000097          	auipc	ra,0x0
    80005a78:	d38080e7          	jalr	-712(ra) # 800057ac <argfd>
    80005a7c:	87aa                	mv	a5,a0
    return -1;
    80005a7e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a80:	0007cc63          	bltz	a5,80005a98 <sys_read+0x5e>
  return fileread(f, p, n);
    80005a84:	fe442603          	lw	a2,-28(s0)
    80005a88:	fd843583          	ld	a1,-40(s0)
    80005a8c:	fe843503          	ld	a0,-24(s0)
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	41c080e7          	jalr	1052(ra) # 80004eac <fileread>
}
    80005a98:	70a2                	ld	ra,40(sp)
    80005a9a:	7402                	ld	s0,32(sp)
    80005a9c:	6145                	addi	sp,sp,48
    80005a9e:	8082                	ret

0000000080005aa0 <sys_write>:
{
    80005aa0:	7179                	addi	sp,sp,-48
    80005aa2:	f406                	sd	ra,40(sp)
    80005aa4:	f022                	sd	s0,32(sp)
    80005aa6:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005aa8:	fd840593          	addi	a1,s0,-40
    80005aac:	4505                	li	a0,1
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	7f2080e7          	jalr	2034(ra) # 800032a0 <argaddr>
  argint(2, &n);
    80005ab6:	fe440593          	addi	a1,s0,-28
    80005aba:	4509                	li	a0,2
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	7c4080e7          	jalr	1988(ra) # 80003280 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ac4:	fe840613          	addi	a2,s0,-24
    80005ac8:	4581                	li	a1,0
    80005aca:	4501                	li	a0,0
    80005acc:	00000097          	auipc	ra,0x0
    80005ad0:	ce0080e7          	jalr	-800(ra) # 800057ac <argfd>
    80005ad4:	87aa                	mv	a5,a0
    return -1;
    80005ad6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ad8:	0007cc63          	bltz	a5,80005af0 <sys_write+0x50>
  return filewrite(f, p, n);
    80005adc:	fe442603          	lw	a2,-28(s0)
    80005ae0:	fd843583          	ld	a1,-40(s0)
    80005ae4:	fe843503          	ld	a0,-24(s0)
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	486080e7          	jalr	1158(ra) # 80004f6e <filewrite>
}
    80005af0:	70a2                	ld	ra,40(sp)
    80005af2:	7402                	ld	s0,32(sp)
    80005af4:	6145                	addi	sp,sp,48
    80005af6:	8082                	ret

0000000080005af8 <sys_close>:
{
    80005af8:	1101                	addi	sp,sp,-32
    80005afa:	ec06                	sd	ra,24(sp)
    80005afc:	e822                	sd	s0,16(sp)
    80005afe:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b00:	fe040613          	addi	a2,s0,-32
    80005b04:	fec40593          	addi	a1,s0,-20
    80005b08:	4501                	li	a0,0
    80005b0a:	00000097          	auipc	ra,0x0
    80005b0e:	ca2080e7          	jalr	-862(ra) # 800057ac <argfd>
    return -1;
    80005b12:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b14:	02054463          	bltz	a0,80005b3c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b18:	ffffc097          	auipc	ra,0xffffc
    80005b1c:	08c080e7          	jalr	140(ra) # 80001ba4 <myproc>
    80005b20:	fec42783          	lw	a5,-20(s0)
    80005b24:	07e9                	addi	a5,a5,26
    80005b26:	078e                	slli	a5,a5,0x3
    80005b28:	97aa                	add	a5,a5,a0
    80005b2a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005b2e:	fe043503          	ld	a0,-32(s0)
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	240080e7          	jalr	576(ra) # 80004d72 <fileclose>
  return 0;
    80005b3a:	4781                	li	a5,0
}
    80005b3c:	853e                	mv	a0,a5
    80005b3e:	60e2                	ld	ra,24(sp)
    80005b40:	6442                	ld	s0,16(sp)
    80005b42:	6105                	addi	sp,sp,32
    80005b44:	8082                	ret

0000000080005b46 <sys_fstat>:
{
    80005b46:	1101                	addi	sp,sp,-32
    80005b48:	ec06                	sd	ra,24(sp)
    80005b4a:	e822                	sd	s0,16(sp)
    80005b4c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005b4e:	fe040593          	addi	a1,s0,-32
    80005b52:	4505                	li	a0,1
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	74c080e7          	jalr	1868(ra) # 800032a0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005b5c:	fe840613          	addi	a2,s0,-24
    80005b60:	4581                	li	a1,0
    80005b62:	4501                	li	a0,0
    80005b64:	00000097          	auipc	ra,0x0
    80005b68:	c48080e7          	jalr	-952(ra) # 800057ac <argfd>
    80005b6c:	87aa                	mv	a5,a0
    return -1;
    80005b6e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005b70:	0007ca63          	bltz	a5,80005b84 <sys_fstat+0x3e>
  return filestat(f, st);
    80005b74:	fe043583          	ld	a1,-32(s0)
    80005b78:	fe843503          	ld	a0,-24(s0)
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	2be080e7          	jalr	702(ra) # 80004e3a <filestat>
}
    80005b84:	60e2                	ld	ra,24(sp)
    80005b86:	6442                	ld	s0,16(sp)
    80005b88:	6105                	addi	sp,sp,32
    80005b8a:	8082                	ret

0000000080005b8c <sys_link>:
{
    80005b8c:	7169                	addi	sp,sp,-304
    80005b8e:	f606                	sd	ra,296(sp)
    80005b90:	f222                	sd	s0,288(sp)
    80005b92:	ee26                	sd	s1,280(sp)
    80005b94:	ea4a                	sd	s2,272(sp)
    80005b96:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005b98:	08000613          	li	a2,128
    80005b9c:	ed040593          	addi	a1,s0,-304
    80005ba0:	4501                	li	a0,0
    80005ba2:	ffffd097          	auipc	ra,0xffffd
    80005ba6:	71e080e7          	jalr	1822(ra) # 800032c0 <argstr>
    return -1;
    80005baa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bac:	10054e63          	bltz	a0,80005cc8 <sys_link+0x13c>
    80005bb0:	08000613          	li	a2,128
    80005bb4:	f5040593          	addi	a1,s0,-176
    80005bb8:	4505                	li	a0,1
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	706080e7          	jalr	1798(ra) # 800032c0 <argstr>
    return -1;
    80005bc2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005bc4:	10054263          	bltz	a0,80005cc8 <sys_link+0x13c>
  begin_op();
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	cde080e7          	jalr	-802(ra) # 800048a6 <begin_op>
  if((ip = namei(old)) == 0){
    80005bd0:	ed040513          	addi	a0,s0,-304
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	ab6080e7          	jalr	-1354(ra) # 8000468a <namei>
    80005bdc:	84aa                	mv	s1,a0
    80005bde:	c551                	beqz	a0,80005c6a <sys_link+0xde>
  ilock(ip);
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	304080e7          	jalr	772(ra) # 80003ee4 <ilock>
  if(ip->type == T_DIR){
    80005be8:	04449703          	lh	a4,68(s1)
    80005bec:	4785                	li	a5,1
    80005bee:	08f70463          	beq	a4,a5,80005c76 <sys_link+0xea>
  ip->nlink++;
    80005bf2:	04a4d783          	lhu	a5,74(s1)
    80005bf6:	2785                	addiw	a5,a5,1
    80005bf8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	21c080e7          	jalr	540(ra) # 80003e1a <iupdate>
  iunlock(ip);
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	39e080e7          	jalr	926(ra) # 80003fa6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c10:	fd040593          	addi	a1,s0,-48
    80005c14:	f5040513          	addi	a0,s0,-176
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	a90080e7          	jalr	-1392(ra) # 800046a8 <nameiparent>
    80005c20:	892a                	mv	s2,a0
    80005c22:	c935                	beqz	a0,80005c96 <sys_link+0x10a>
  ilock(dp);
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	2c0080e7          	jalr	704(ra) # 80003ee4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005c2c:	00092703          	lw	a4,0(s2)
    80005c30:	409c                	lw	a5,0(s1)
    80005c32:	04f71d63          	bne	a4,a5,80005c8c <sys_link+0x100>
    80005c36:	40d0                	lw	a2,4(s1)
    80005c38:	fd040593          	addi	a1,s0,-48
    80005c3c:	854a                	mv	a0,s2
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	99a080e7          	jalr	-1638(ra) # 800045d8 <dirlink>
    80005c46:	04054363          	bltz	a0,80005c8c <sys_link+0x100>
  iunlockput(dp);
    80005c4a:	854a                	mv	a0,s2
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	4fa080e7          	jalr	1274(ra) # 80004146 <iunlockput>
  iput(ip);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	448080e7          	jalr	1096(ra) # 8000409e <iput>
  end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	cc8080e7          	jalr	-824(ra) # 80004926 <end_op>
  return 0;
    80005c66:	4781                	li	a5,0
    80005c68:	a085                	j	80005cc8 <sys_link+0x13c>
    end_op();
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	cbc080e7          	jalr	-836(ra) # 80004926 <end_op>
    return -1;
    80005c72:	57fd                	li	a5,-1
    80005c74:	a891                	j	80005cc8 <sys_link+0x13c>
    iunlockput(ip);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	4ce080e7          	jalr	1230(ra) # 80004146 <iunlockput>
    end_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	ca6080e7          	jalr	-858(ra) # 80004926 <end_op>
    return -1;
    80005c88:	57fd                	li	a5,-1
    80005c8a:	a83d                	j	80005cc8 <sys_link+0x13c>
    iunlockput(dp);
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	4b8080e7          	jalr	1208(ra) # 80004146 <iunlockput>
  ilock(ip);
    80005c96:	8526                	mv	a0,s1
    80005c98:	ffffe097          	auipc	ra,0xffffe
    80005c9c:	24c080e7          	jalr	588(ra) # 80003ee4 <ilock>
  ip->nlink--;
    80005ca0:	04a4d783          	lhu	a5,74(s1)
    80005ca4:	37fd                	addiw	a5,a5,-1
    80005ca6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005caa:	8526                	mv	a0,s1
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	16e080e7          	jalr	366(ra) # 80003e1a <iupdate>
  iunlockput(ip);
    80005cb4:	8526                	mv	a0,s1
    80005cb6:	ffffe097          	auipc	ra,0xffffe
    80005cba:	490080e7          	jalr	1168(ra) # 80004146 <iunlockput>
  end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	c68080e7          	jalr	-920(ra) # 80004926 <end_op>
  return -1;
    80005cc6:	57fd                	li	a5,-1
}
    80005cc8:	853e                	mv	a0,a5
    80005cca:	70b2                	ld	ra,296(sp)
    80005ccc:	7412                	ld	s0,288(sp)
    80005cce:	64f2                	ld	s1,280(sp)
    80005cd0:	6952                	ld	s2,272(sp)
    80005cd2:	6155                	addi	sp,sp,304
    80005cd4:	8082                	ret

0000000080005cd6 <sys_unlink>:
{
    80005cd6:	7151                	addi	sp,sp,-240
    80005cd8:	f586                	sd	ra,232(sp)
    80005cda:	f1a2                	sd	s0,224(sp)
    80005cdc:	eda6                	sd	s1,216(sp)
    80005cde:	e9ca                	sd	s2,208(sp)
    80005ce0:	e5ce                	sd	s3,200(sp)
    80005ce2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f3040593          	addi	a1,s0,-208
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	5d2080e7          	jalr	1490(ra) # 800032c0 <argstr>
    80005cf6:	18054163          	bltz	a0,80005e78 <sys_unlink+0x1a2>
  begin_op();
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	bac080e7          	jalr	-1108(ra) # 800048a6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d02:	fb040593          	addi	a1,s0,-80
    80005d06:	f3040513          	addi	a0,s0,-208
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	99e080e7          	jalr	-1634(ra) # 800046a8 <nameiparent>
    80005d12:	84aa                	mv	s1,a0
    80005d14:	c979                	beqz	a0,80005dea <sys_unlink+0x114>
  ilock(dp);
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	1ce080e7          	jalr	462(ra) # 80003ee4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005d1e:	00003597          	auipc	a1,0x3
    80005d22:	a3a58593          	addi	a1,a1,-1478 # 80008758 <syscalls+0x2d0>
    80005d26:	fb040513          	addi	a0,s0,-80
    80005d2a:	ffffe097          	auipc	ra,0xffffe
    80005d2e:	684080e7          	jalr	1668(ra) # 800043ae <namecmp>
    80005d32:	14050a63          	beqz	a0,80005e86 <sys_unlink+0x1b0>
    80005d36:	00003597          	auipc	a1,0x3
    80005d3a:	a2a58593          	addi	a1,a1,-1494 # 80008760 <syscalls+0x2d8>
    80005d3e:	fb040513          	addi	a0,s0,-80
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	66c080e7          	jalr	1644(ra) # 800043ae <namecmp>
    80005d4a:	12050e63          	beqz	a0,80005e86 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005d4e:	f2c40613          	addi	a2,s0,-212
    80005d52:	fb040593          	addi	a1,s0,-80
    80005d56:	8526                	mv	a0,s1
    80005d58:	ffffe097          	auipc	ra,0xffffe
    80005d5c:	670080e7          	jalr	1648(ra) # 800043c8 <dirlookup>
    80005d60:	892a                	mv	s2,a0
    80005d62:	12050263          	beqz	a0,80005e86 <sys_unlink+0x1b0>
  ilock(ip);
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	17e080e7          	jalr	382(ra) # 80003ee4 <ilock>
  if(ip->nlink < 1)
    80005d6e:	04a91783          	lh	a5,74(s2)
    80005d72:	08f05263          	blez	a5,80005df6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005d76:	04491703          	lh	a4,68(s2)
    80005d7a:	4785                	li	a5,1
    80005d7c:	08f70563          	beq	a4,a5,80005e06 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005d80:	4641                	li	a2,16
    80005d82:	4581                	li	a1,0
    80005d84:	fc040513          	addi	a0,s0,-64
    80005d88:	ffffb097          	auipc	ra,0xffffb
    80005d8c:	07a080e7          	jalr	122(ra) # 80000e02 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d90:	4741                	li	a4,16
    80005d92:	f2c42683          	lw	a3,-212(s0)
    80005d96:	fc040613          	addi	a2,s0,-64
    80005d9a:	4581                	li	a1,0
    80005d9c:	8526                	mv	a0,s1
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	4f2080e7          	jalr	1266(ra) # 80004290 <writei>
    80005da6:	47c1                	li	a5,16
    80005da8:	0af51563          	bne	a0,a5,80005e52 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005dac:	04491703          	lh	a4,68(s2)
    80005db0:	4785                	li	a5,1
    80005db2:	0af70863          	beq	a4,a5,80005e62 <sys_unlink+0x18c>
  iunlockput(dp);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	38e080e7          	jalr	910(ra) # 80004146 <iunlockput>
  ip->nlink--;
    80005dc0:	04a95783          	lhu	a5,74(s2)
    80005dc4:	37fd                	addiw	a5,a5,-1
    80005dc6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005dca:	854a                	mv	a0,s2
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	04e080e7          	jalr	78(ra) # 80003e1a <iupdate>
  iunlockput(ip);
    80005dd4:	854a                	mv	a0,s2
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	370080e7          	jalr	880(ra) # 80004146 <iunlockput>
  end_op();
    80005dde:	fffff097          	auipc	ra,0xfffff
    80005de2:	b48080e7          	jalr	-1208(ra) # 80004926 <end_op>
  return 0;
    80005de6:	4501                	li	a0,0
    80005de8:	a84d                	j	80005e9a <sys_unlink+0x1c4>
    end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	b3c080e7          	jalr	-1220(ra) # 80004926 <end_op>
    return -1;
    80005df2:	557d                	li	a0,-1
    80005df4:	a05d                	j	80005e9a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005df6:	00003517          	auipc	a0,0x3
    80005dfa:	97250513          	addi	a0,a0,-1678 # 80008768 <syscalls+0x2e0>
    80005dfe:	ffffa097          	auipc	ra,0xffffa
    80005e02:	740080e7          	jalr	1856(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e06:	04c92703          	lw	a4,76(s2)
    80005e0a:	02000793          	li	a5,32
    80005e0e:	f6e7f9e3          	bgeu	a5,a4,80005d80 <sys_unlink+0xaa>
    80005e12:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e16:	4741                	li	a4,16
    80005e18:	86ce                	mv	a3,s3
    80005e1a:	f1840613          	addi	a2,s0,-232
    80005e1e:	4581                	li	a1,0
    80005e20:	854a                	mv	a0,s2
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	376080e7          	jalr	886(ra) # 80004198 <readi>
    80005e2a:	47c1                	li	a5,16
    80005e2c:	00f51b63          	bne	a0,a5,80005e42 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005e30:	f1845783          	lhu	a5,-232(s0)
    80005e34:	e7a1                	bnez	a5,80005e7c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e36:	29c1                	addiw	s3,s3,16
    80005e38:	04c92783          	lw	a5,76(s2)
    80005e3c:	fcf9ede3          	bltu	s3,a5,80005e16 <sys_unlink+0x140>
    80005e40:	b781                	j	80005d80 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	93e50513          	addi	a0,a0,-1730 # 80008780 <syscalls+0x2f8>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005e52:	00003517          	auipc	a0,0x3
    80005e56:	94650513          	addi	a0,a0,-1722 # 80008798 <syscalls+0x310>
    80005e5a:	ffffa097          	auipc	ra,0xffffa
    80005e5e:	6e4080e7          	jalr	1764(ra) # 8000053e <panic>
    dp->nlink--;
    80005e62:	04a4d783          	lhu	a5,74(s1)
    80005e66:	37fd                	addiw	a5,a5,-1
    80005e68:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005e6c:	8526                	mv	a0,s1
    80005e6e:	ffffe097          	auipc	ra,0xffffe
    80005e72:	fac080e7          	jalr	-84(ra) # 80003e1a <iupdate>
    80005e76:	b781                	j	80005db6 <sys_unlink+0xe0>
    return -1;
    80005e78:	557d                	li	a0,-1
    80005e7a:	a005                	j	80005e9a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005e7c:	854a                	mv	a0,s2
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	2c8080e7          	jalr	712(ra) # 80004146 <iunlockput>
  iunlockput(dp);
    80005e86:	8526                	mv	a0,s1
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	2be080e7          	jalr	702(ra) # 80004146 <iunlockput>
  end_op();
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	a96080e7          	jalr	-1386(ra) # 80004926 <end_op>
  return -1;
    80005e98:	557d                	li	a0,-1
}
    80005e9a:	70ae                	ld	ra,232(sp)
    80005e9c:	740e                	ld	s0,224(sp)
    80005e9e:	64ee                	ld	s1,216(sp)
    80005ea0:	694e                	ld	s2,208(sp)
    80005ea2:	69ae                	ld	s3,200(sp)
    80005ea4:	616d                	addi	sp,sp,240
    80005ea6:	8082                	ret

0000000080005ea8 <sys_open>:

uint64
sys_open(void)
{
    80005ea8:	7131                	addi	sp,sp,-192
    80005eaa:	fd06                	sd	ra,184(sp)
    80005eac:	f922                	sd	s0,176(sp)
    80005eae:	f526                	sd	s1,168(sp)
    80005eb0:	f14a                	sd	s2,160(sp)
    80005eb2:	ed4e                	sd	s3,152(sp)
    80005eb4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005eb6:	f4c40593          	addi	a1,s0,-180
    80005eba:	4505                	li	a0,1
    80005ebc:	ffffd097          	auipc	ra,0xffffd
    80005ec0:	3c4080e7          	jalr	964(ra) # 80003280 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005ec4:	08000613          	li	a2,128
    80005ec8:	f5040593          	addi	a1,s0,-176
    80005ecc:	4501                	li	a0,0
    80005ece:	ffffd097          	auipc	ra,0xffffd
    80005ed2:	3f2080e7          	jalr	1010(ra) # 800032c0 <argstr>
    80005ed6:	87aa                	mv	a5,a0
    return -1;
    80005ed8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005eda:	0a07c963          	bltz	a5,80005f8c <sys_open+0xe4>

  begin_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	9c8080e7          	jalr	-1592(ra) # 800048a6 <begin_op>

  if(omode & O_CREATE){
    80005ee6:	f4c42783          	lw	a5,-180(s0)
    80005eea:	2007f793          	andi	a5,a5,512
    80005eee:	cfc5                	beqz	a5,80005fa6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ef0:	4681                	li	a3,0
    80005ef2:	4601                	li	a2,0
    80005ef4:	4589                	li	a1,2
    80005ef6:	f5040513          	addi	a0,s0,-176
    80005efa:	00000097          	auipc	ra,0x0
    80005efe:	954080e7          	jalr	-1708(ra) # 8000584e <create>
    80005f02:	84aa                	mv	s1,a0
    if(ip == 0){
    80005f04:	c959                	beqz	a0,80005f9a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f06:	04449703          	lh	a4,68(s1)
    80005f0a:	478d                	li	a5,3
    80005f0c:	00f71763          	bne	a4,a5,80005f1a <sys_open+0x72>
    80005f10:	0464d703          	lhu	a4,70(s1)
    80005f14:	47a5                	li	a5,9
    80005f16:	0ce7ed63          	bltu	a5,a4,80005ff0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	d9c080e7          	jalr	-612(ra) # 80004cb6 <filealloc>
    80005f22:	89aa                	mv	s3,a0
    80005f24:	10050363          	beqz	a0,8000602a <sys_open+0x182>
    80005f28:	00000097          	auipc	ra,0x0
    80005f2c:	8e4080e7          	jalr	-1820(ra) # 8000580c <fdalloc>
    80005f30:	892a                	mv	s2,a0
    80005f32:	0e054763          	bltz	a0,80006020 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f36:	04449703          	lh	a4,68(s1)
    80005f3a:	478d                	li	a5,3
    80005f3c:	0cf70563          	beq	a4,a5,80006006 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f40:	4789                	li	a5,2
    80005f42:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f46:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f4a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f4e:	f4c42783          	lw	a5,-180(s0)
    80005f52:	0017c713          	xori	a4,a5,1
    80005f56:	8b05                	andi	a4,a4,1
    80005f58:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f5c:	0037f713          	andi	a4,a5,3
    80005f60:	00e03733          	snez	a4,a4
    80005f64:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f68:	4007f793          	andi	a5,a5,1024
    80005f6c:	c791                	beqz	a5,80005f78 <sys_open+0xd0>
    80005f6e:	04449703          	lh	a4,68(s1)
    80005f72:	4789                	li	a5,2
    80005f74:	0af70063          	beq	a4,a5,80006014 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f78:	8526                	mv	a0,s1
    80005f7a:	ffffe097          	auipc	ra,0xffffe
    80005f7e:	02c080e7          	jalr	44(ra) # 80003fa6 <iunlock>
  end_op();
    80005f82:	fffff097          	auipc	ra,0xfffff
    80005f86:	9a4080e7          	jalr	-1628(ra) # 80004926 <end_op>

  return fd;
    80005f8a:	854a                	mv	a0,s2
}
    80005f8c:	70ea                	ld	ra,184(sp)
    80005f8e:	744a                	ld	s0,176(sp)
    80005f90:	74aa                	ld	s1,168(sp)
    80005f92:	790a                	ld	s2,160(sp)
    80005f94:	69ea                	ld	s3,152(sp)
    80005f96:	6129                	addi	sp,sp,192
    80005f98:	8082                	ret
      end_op();
    80005f9a:	fffff097          	auipc	ra,0xfffff
    80005f9e:	98c080e7          	jalr	-1652(ra) # 80004926 <end_op>
      return -1;
    80005fa2:	557d                	li	a0,-1
    80005fa4:	b7e5                	j	80005f8c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005fa6:	f5040513          	addi	a0,s0,-176
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	6e0080e7          	jalr	1760(ra) # 8000468a <namei>
    80005fb2:	84aa                	mv	s1,a0
    80005fb4:	c905                	beqz	a0,80005fe4 <sys_open+0x13c>
    ilock(ip);
    80005fb6:	ffffe097          	auipc	ra,0xffffe
    80005fba:	f2e080e7          	jalr	-210(ra) # 80003ee4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fbe:	04449703          	lh	a4,68(s1)
    80005fc2:	4785                	li	a5,1
    80005fc4:	f4f711e3          	bne	a4,a5,80005f06 <sys_open+0x5e>
    80005fc8:	f4c42783          	lw	a5,-180(s0)
    80005fcc:	d7b9                	beqz	a5,80005f1a <sys_open+0x72>
      iunlockput(ip);
    80005fce:	8526                	mv	a0,s1
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	176080e7          	jalr	374(ra) # 80004146 <iunlockput>
      end_op();
    80005fd8:	fffff097          	auipc	ra,0xfffff
    80005fdc:	94e080e7          	jalr	-1714(ra) # 80004926 <end_op>
      return -1;
    80005fe0:	557d                	li	a0,-1
    80005fe2:	b76d                	j	80005f8c <sys_open+0xe4>
      end_op();
    80005fe4:	fffff097          	auipc	ra,0xfffff
    80005fe8:	942080e7          	jalr	-1726(ra) # 80004926 <end_op>
      return -1;
    80005fec:	557d                	li	a0,-1
    80005fee:	bf79                	j	80005f8c <sys_open+0xe4>
    iunlockput(ip);
    80005ff0:	8526                	mv	a0,s1
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	154080e7          	jalr	340(ra) # 80004146 <iunlockput>
    end_op();
    80005ffa:	fffff097          	auipc	ra,0xfffff
    80005ffe:	92c080e7          	jalr	-1748(ra) # 80004926 <end_op>
    return -1;
    80006002:	557d                	li	a0,-1
    80006004:	b761                	j	80005f8c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006006:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000600a:	04649783          	lh	a5,70(s1)
    8000600e:	02f99223          	sh	a5,36(s3)
    80006012:	bf25                	j	80005f4a <sys_open+0xa2>
    itrunc(ip);
    80006014:	8526                	mv	a0,s1
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	fdc080e7          	jalr	-36(ra) # 80003ff2 <itrunc>
    8000601e:	bfa9                	j	80005f78 <sys_open+0xd0>
      fileclose(f);
    80006020:	854e                	mv	a0,s3
    80006022:	fffff097          	auipc	ra,0xfffff
    80006026:	d50080e7          	jalr	-688(ra) # 80004d72 <fileclose>
    iunlockput(ip);
    8000602a:	8526                	mv	a0,s1
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	11a080e7          	jalr	282(ra) # 80004146 <iunlockput>
    end_op();
    80006034:	fffff097          	auipc	ra,0xfffff
    80006038:	8f2080e7          	jalr	-1806(ra) # 80004926 <end_op>
    return -1;
    8000603c:	557d                	li	a0,-1
    8000603e:	b7b9                	j	80005f8c <sys_open+0xe4>

0000000080006040 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006040:	7175                	addi	sp,sp,-144
    80006042:	e506                	sd	ra,136(sp)
    80006044:	e122                	sd	s0,128(sp)
    80006046:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006048:	fffff097          	auipc	ra,0xfffff
    8000604c:	85e080e7          	jalr	-1954(ra) # 800048a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006050:	08000613          	li	a2,128
    80006054:	f7040593          	addi	a1,s0,-144
    80006058:	4501                	li	a0,0
    8000605a:	ffffd097          	auipc	ra,0xffffd
    8000605e:	266080e7          	jalr	614(ra) # 800032c0 <argstr>
    80006062:	02054963          	bltz	a0,80006094 <sys_mkdir+0x54>
    80006066:	4681                	li	a3,0
    80006068:	4601                	li	a2,0
    8000606a:	4585                	li	a1,1
    8000606c:	f7040513          	addi	a0,s0,-144
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	7de080e7          	jalr	2014(ra) # 8000584e <create>
    80006078:	cd11                	beqz	a0,80006094 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000607a:	ffffe097          	auipc	ra,0xffffe
    8000607e:	0cc080e7          	jalr	204(ra) # 80004146 <iunlockput>
  end_op();
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	8a4080e7          	jalr	-1884(ra) # 80004926 <end_op>
  return 0;
    8000608a:	4501                	li	a0,0
}
    8000608c:	60aa                	ld	ra,136(sp)
    8000608e:	640a                	ld	s0,128(sp)
    80006090:	6149                	addi	sp,sp,144
    80006092:	8082                	ret
    end_op();
    80006094:	fffff097          	auipc	ra,0xfffff
    80006098:	892080e7          	jalr	-1902(ra) # 80004926 <end_op>
    return -1;
    8000609c:	557d                	li	a0,-1
    8000609e:	b7fd                	j	8000608c <sys_mkdir+0x4c>

00000000800060a0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800060a0:	7135                	addi	sp,sp,-160
    800060a2:	ed06                	sd	ra,152(sp)
    800060a4:	e922                	sd	s0,144(sp)
    800060a6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	7fe080e7          	jalr	2046(ra) # 800048a6 <begin_op>
  argint(1, &major);
    800060b0:	f6c40593          	addi	a1,s0,-148
    800060b4:	4505                	li	a0,1
    800060b6:	ffffd097          	auipc	ra,0xffffd
    800060ba:	1ca080e7          	jalr	458(ra) # 80003280 <argint>
  argint(2, &minor);
    800060be:	f6840593          	addi	a1,s0,-152
    800060c2:	4509                	li	a0,2
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	1bc080e7          	jalr	444(ra) # 80003280 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060cc:	08000613          	li	a2,128
    800060d0:	f7040593          	addi	a1,s0,-144
    800060d4:	4501                	li	a0,0
    800060d6:	ffffd097          	auipc	ra,0xffffd
    800060da:	1ea080e7          	jalr	490(ra) # 800032c0 <argstr>
    800060de:	02054b63          	bltz	a0,80006114 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060e2:	f6841683          	lh	a3,-152(s0)
    800060e6:	f6c41603          	lh	a2,-148(s0)
    800060ea:	458d                	li	a1,3
    800060ec:	f7040513          	addi	a0,s0,-144
    800060f0:	fffff097          	auipc	ra,0xfffff
    800060f4:	75e080e7          	jalr	1886(ra) # 8000584e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060f8:	cd11                	beqz	a0,80006114 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	04c080e7          	jalr	76(ra) # 80004146 <iunlockput>
  end_op();
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	824080e7          	jalr	-2012(ra) # 80004926 <end_op>
  return 0;
    8000610a:	4501                	li	a0,0
}
    8000610c:	60ea                	ld	ra,152(sp)
    8000610e:	644a                	ld	s0,144(sp)
    80006110:	610d                	addi	sp,sp,160
    80006112:	8082                	ret
    end_op();
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	812080e7          	jalr	-2030(ra) # 80004926 <end_op>
    return -1;
    8000611c:	557d                	li	a0,-1
    8000611e:	b7fd                	j	8000610c <sys_mknod+0x6c>

0000000080006120 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006120:	7135                	addi	sp,sp,-160
    80006122:	ed06                	sd	ra,152(sp)
    80006124:	e922                	sd	s0,144(sp)
    80006126:	e526                	sd	s1,136(sp)
    80006128:	e14a                	sd	s2,128(sp)
    8000612a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000612c:	ffffc097          	auipc	ra,0xffffc
    80006130:	a78080e7          	jalr	-1416(ra) # 80001ba4 <myproc>
    80006134:	892a                	mv	s2,a0
  
  begin_op();
    80006136:	ffffe097          	auipc	ra,0xffffe
    8000613a:	770080e7          	jalr	1904(ra) # 800048a6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000613e:	08000613          	li	a2,128
    80006142:	f6040593          	addi	a1,s0,-160
    80006146:	4501                	li	a0,0
    80006148:	ffffd097          	auipc	ra,0xffffd
    8000614c:	178080e7          	jalr	376(ra) # 800032c0 <argstr>
    80006150:	04054b63          	bltz	a0,800061a6 <sys_chdir+0x86>
    80006154:	f6040513          	addi	a0,s0,-160
    80006158:	ffffe097          	auipc	ra,0xffffe
    8000615c:	532080e7          	jalr	1330(ra) # 8000468a <namei>
    80006160:	84aa                	mv	s1,a0
    80006162:	c131                	beqz	a0,800061a6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006164:	ffffe097          	auipc	ra,0xffffe
    80006168:	d80080e7          	jalr	-640(ra) # 80003ee4 <ilock>
  if(ip->type != T_DIR){
    8000616c:	04449703          	lh	a4,68(s1)
    80006170:	4785                	li	a5,1
    80006172:	04f71063          	bne	a4,a5,800061b2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006176:	8526                	mv	a0,s1
    80006178:	ffffe097          	auipc	ra,0xffffe
    8000617c:	e2e080e7          	jalr	-466(ra) # 80003fa6 <iunlock>
  iput(p->cwd);
    80006180:	15093503          	ld	a0,336(s2)
    80006184:	ffffe097          	auipc	ra,0xffffe
    80006188:	f1a080e7          	jalr	-230(ra) # 8000409e <iput>
  end_op();
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	79a080e7          	jalr	1946(ra) # 80004926 <end_op>
  p->cwd = ip;
    80006194:	14993823          	sd	s1,336(s2)
  return 0;
    80006198:	4501                	li	a0,0
}
    8000619a:	60ea                	ld	ra,152(sp)
    8000619c:	644a                	ld	s0,144(sp)
    8000619e:	64aa                	ld	s1,136(sp)
    800061a0:	690a                	ld	s2,128(sp)
    800061a2:	610d                	addi	sp,sp,160
    800061a4:	8082                	ret
    end_op();
    800061a6:	ffffe097          	auipc	ra,0xffffe
    800061aa:	780080e7          	jalr	1920(ra) # 80004926 <end_op>
    return -1;
    800061ae:	557d                	li	a0,-1
    800061b0:	b7ed                	j	8000619a <sys_chdir+0x7a>
    iunlockput(ip);
    800061b2:	8526                	mv	a0,s1
    800061b4:	ffffe097          	auipc	ra,0xffffe
    800061b8:	f92080e7          	jalr	-110(ra) # 80004146 <iunlockput>
    end_op();
    800061bc:	ffffe097          	auipc	ra,0xffffe
    800061c0:	76a080e7          	jalr	1898(ra) # 80004926 <end_op>
    return -1;
    800061c4:	557d                	li	a0,-1
    800061c6:	bfd1                	j	8000619a <sys_chdir+0x7a>

00000000800061c8 <sys_exec>:

uint64
sys_exec(void)
{
    800061c8:	7145                	addi	sp,sp,-464
    800061ca:	e786                	sd	ra,456(sp)
    800061cc:	e3a2                	sd	s0,448(sp)
    800061ce:	ff26                	sd	s1,440(sp)
    800061d0:	fb4a                	sd	s2,432(sp)
    800061d2:	f74e                	sd	s3,424(sp)
    800061d4:	f352                	sd	s4,416(sp)
    800061d6:	ef56                	sd	s5,408(sp)
    800061d8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800061da:	e3840593          	addi	a1,s0,-456
    800061de:	4505                	li	a0,1
    800061e0:	ffffd097          	auipc	ra,0xffffd
    800061e4:	0c0080e7          	jalr	192(ra) # 800032a0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    800061e8:	08000613          	li	a2,128
    800061ec:	f4040593          	addi	a1,s0,-192
    800061f0:	4501                	li	a0,0
    800061f2:	ffffd097          	auipc	ra,0xffffd
    800061f6:	0ce080e7          	jalr	206(ra) # 800032c0 <argstr>
    800061fa:	87aa                	mv	a5,a0
    return -1;
    800061fc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800061fe:	0c07c263          	bltz	a5,800062c2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006202:	10000613          	li	a2,256
    80006206:	4581                	li	a1,0
    80006208:	e4040513          	addi	a0,s0,-448
    8000620c:	ffffb097          	auipc	ra,0xffffb
    80006210:	bf6080e7          	jalr	-1034(ra) # 80000e02 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006214:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006218:	89a6                	mv	s3,s1
    8000621a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000621c:	02000a13          	li	s4,32
    80006220:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006224:	00391793          	slli	a5,s2,0x3
    80006228:	e3040593          	addi	a1,s0,-464
    8000622c:	e3843503          	ld	a0,-456(s0)
    80006230:	953e                	add	a0,a0,a5
    80006232:	ffffd097          	auipc	ra,0xffffd
    80006236:	fb0080e7          	jalr	-80(ra) # 800031e2 <fetchaddr>
    8000623a:	02054a63          	bltz	a0,8000626e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    8000623e:	e3043783          	ld	a5,-464(s0)
    80006242:	c3b9                	beqz	a5,80006288 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006244:	ffffb097          	auipc	ra,0xffffb
    80006248:	994080e7          	jalr	-1644(ra) # 80000bd8 <kalloc>
    8000624c:	85aa                	mv	a1,a0
    8000624e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006252:	cd11                	beqz	a0,8000626e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006254:	6605                	lui	a2,0x1
    80006256:	e3043503          	ld	a0,-464(s0)
    8000625a:	ffffd097          	auipc	ra,0xffffd
    8000625e:	fda080e7          	jalr	-38(ra) # 80003234 <fetchstr>
    80006262:	00054663          	bltz	a0,8000626e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006266:	0905                	addi	s2,s2,1
    80006268:	09a1                	addi	s3,s3,8
    8000626a:	fb491be3          	bne	s2,s4,80006220 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000626e:	10048913          	addi	s2,s1,256
    80006272:	6088                	ld	a0,0(s1)
    80006274:	c531                	beqz	a0,800062c0 <sys_exec+0xf8>
    kfree(argv[i]);
    80006276:	ffffa097          	auipc	ra,0xffffa
    8000627a:	774080e7          	jalr	1908(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000627e:	04a1                	addi	s1,s1,8
    80006280:	ff2499e3          	bne	s1,s2,80006272 <sys_exec+0xaa>
  return -1;
    80006284:	557d                	li	a0,-1
    80006286:	a835                	j	800062c2 <sys_exec+0xfa>
      argv[i] = 0;
    80006288:	0a8e                	slli	s5,s5,0x3
    8000628a:	fc040793          	addi	a5,s0,-64
    8000628e:	9abe                	add	s5,s5,a5
    80006290:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006294:	e4040593          	addi	a1,s0,-448
    80006298:	f4040513          	addi	a0,s0,-192
    8000629c:	fffff097          	auipc	ra,0xfffff
    800062a0:	150080e7          	jalr	336(ra) # 800053ec <exec>
    800062a4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a6:	10048993          	addi	s3,s1,256
    800062aa:	6088                	ld	a0,0(s1)
    800062ac:	c901                	beqz	a0,800062bc <sys_exec+0xf4>
    kfree(argv[i]);
    800062ae:	ffffa097          	auipc	ra,0xffffa
    800062b2:	73c080e7          	jalr	1852(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062b6:	04a1                	addi	s1,s1,8
    800062b8:	ff3499e3          	bne	s1,s3,800062aa <sys_exec+0xe2>
  return ret;
    800062bc:	854a                	mv	a0,s2
    800062be:	a011                	j	800062c2 <sys_exec+0xfa>
  return -1;
    800062c0:	557d                	li	a0,-1
}
    800062c2:	60be                	ld	ra,456(sp)
    800062c4:	641e                	ld	s0,448(sp)
    800062c6:	74fa                	ld	s1,440(sp)
    800062c8:	795a                	ld	s2,432(sp)
    800062ca:	79ba                	ld	s3,424(sp)
    800062cc:	7a1a                	ld	s4,416(sp)
    800062ce:	6afa                	ld	s5,408(sp)
    800062d0:	6179                	addi	sp,sp,464
    800062d2:	8082                	ret

00000000800062d4 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062d4:	7139                	addi	sp,sp,-64
    800062d6:	fc06                	sd	ra,56(sp)
    800062d8:	f822                	sd	s0,48(sp)
    800062da:	f426                	sd	s1,40(sp)
    800062dc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062de:	ffffc097          	auipc	ra,0xffffc
    800062e2:	8c6080e7          	jalr	-1850(ra) # 80001ba4 <myproc>
    800062e6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    800062e8:	fd840593          	addi	a1,s0,-40
    800062ec:	4501                	li	a0,0
    800062ee:	ffffd097          	auipc	ra,0xffffd
    800062f2:	fb2080e7          	jalr	-78(ra) # 800032a0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800062f6:	fc840593          	addi	a1,s0,-56
    800062fa:	fd040513          	addi	a0,s0,-48
    800062fe:	fffff097          	auipc	ra,0xfffff
    80006302:	da4080e7          	jalr	-604(ra) # 800050a2 <pipealloc>
    return -1;
    80006306:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006308:	0c054463          	bltz	a0,800063d0 <sys_pipe+0xfc>
  fd0 = -1;
    8000630c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006310:	fd043503          	ld	a0,-48(s0)
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	4f8080e7          	jalr	1272(ra) # 8000580c <fdalloc>
    8000631c:	fca42223          	sw	a0,-60(s0)
    80006320:	08054b63          	bltz	a0,800063b6 <sys_pipe+0xe2>
    80006324:	fc843503          	ld	a0,-56(s0)
    80006328:	fffff097          	auipc	ra,0xfffff
    8000632c:	4e4080e7          	jalr	1252(ra) # 8000580c <fdalloc>
    80006330:	fca42023          	sw	a0,-64(s0)
    80006334:	06054863          	bltz	a0,800063a4 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006338:	4691                	li	a3,4
    8000633a:	fc440613          	addi	a2,s0,-60
    8000633e:	fd843583          	ld	a1,-40(s0)
    80006342:	68a8                	ld	a0,80(s1)
    80006344:	ffffb097          	auipc	ra,0xffffb
    80006348:	49a080e7          	jalr	1178(ra) # 800017de <copyout>
    8000634c:	02054063          	bltz	a0,8000636c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006350:	4691                	li	a3,4
    80006352:	fc040613          	addi	a2,s0,-64
    80006356:	fd843583          	ld	a1,-40(s0)
    8000635a:	0591                	addi	a1,a1,4
    8000635c:	68a8                	ld	a0,80(s1)
    8000635e:	ffffb097          	auipc	ra,0xffffb
    80006362:	480080e7          	jalr	1152(ra) # 800017de <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006366:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006368:	06055463          	bgez	a0,800063d0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000636c:	fc442783          	lw	a5,-60(s0)
    80006370:	07e9                	addi	a5,a5,26
    80006372:	078e                	slli	a5,a5,0x3
    80006374:	97a6                	add	a5,a5,s1
    80006376:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000637a:	fc042503          	lw	a0,-64(s0)
    8000637e:	0569                	addi	a0,a0,26
    80006380:	050e                	slli	a0,a0,0x3
    80006382:	94aa                	add	s1,s1,a0
    80006384:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006388:	fd043503          	ld	a0,-48(s0)
    8000638c:	fffff097          	auipc	ra,0xfffff
    80006390:	9e6080e7          	jalr	-1562(ra) # 80004d72 <fileclose>
    fileclose(wf);
    80006394:	fc843503          	ld	a0,-56(s0)
    80006398:	fffff097          	auipc	ra,0xfffff
    8000639c:	9da080e7          	jalr	-1574(ra) # 80004d72 <fileclose>
    return -1;
    800063a0:	57fd                	li	a5,-1
    800063a2:	a03d                	j	800063d0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800063a4:	fc442783          	lw	a5,-60(s0)
    800063a8:	0007c763          	bltz	a5,800063b6 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800063ac:	07e9                	addi	a5,a5,26
    800063ae:	078e                	slli	a5,a5,0x3
    800063b0:	94be                	add	s1,s1,a5
    800063b2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800063b6:	fd043503          	ld	a0,-48(s0)
    800063ba:	fffff097          	auipc	ra,0xfffff
    800063be:	9b8080e7          	jalr	-1608(ra) # 80004d72 <fileclose>
    fileclose(wf);
    800063c2:	fc843503          	ld	a0,-56(s0)
    800063c6:	fffff097          	auipc	ra,0xfffff
    800063ca:	9ac080e7          	jalr	-1620(ra) # 80004d72 <fileclose>
    return -1;
    800063ce:	57fd                	li	a5,-1
}
    800063d0:	853e                	mv	a0,a5
    800063d2:	70e2                	ld	ra,56(sp)
    800063d4:	7442                	ld	s0,48(sp)
    800063d6:	74a2                	ld	s1,40(sp)
    800063d8:	6121                	addi	sp,sp,64
    800063da:	8082                	ret
    800063dc:	0000                	unimp
	...

00000000800063e0 <kernelvec>:
    800063e0:	7111                	addi	sp,sp,-256
    800063e2:	e006                	sd	ra,0(sp)
    800063e4:	e40a                	sd	sp,8(sp)
    800063e6:	e80e                	sd	gp,16(sp)
    800063e8:	ec12                	sd	tp,24(sp)
    800063ea:	f016                	sd	t0,32(sp)
    800063ec:	f41a                	sd	t1,40(sp)
    800063ee:	f81e                	sd	t2,48(sp)
    800063f0:	fc22                	sd	s0,56(sp)
    800063f2:	e0a6                	sd	s1,64(sp)
    800063f4:	e4aa                	sd	a0,72(sp)
    800063f6:	e8ae                	sd	a1,80(sp)
    800063f8:	ecb2                	sd	a2,88(sp)
    800063fa:	f0b6                	sd	a3,96(sp)
    800063fc:	f4ba                	sd	a4,104(sp)
    800063fe:	f8be                	sd	a5,112(sp)
    80006400:	fcc2                	sd	a6,120(sp)
    80006402:	e146                	sd	a7,128(sp)
    80006404:	e54a                	sd	s2,136(sp)
    80006406:	e94e                	sd	s3,144(sp)
    80006408:	ed52                	sd	s4,152(sp)
    8000640a:	f156                	sd	s5,160(sp)
    8000640c:	f55a                	sd	s6,168(sp)
    8000640e:	f95e                	sd	s7,176(sp)
    80006410:	fd62                	sd	s8,184(sp)
    80006412:	e1e6                	sd	s9,192(sp)
    80006414:	e5ea                	sd	s10,200(sp)
    80006416:	e9ee                	sd	s11,208(sp)
    80006418:	edf2                	sd	t3,216(sp)
    8000641a:	f1f6                	sd	t4,224(sp)
    8000641c:	f5fa                	sd	t5,232(sp)
    8000641e:	f9fe                	sd	t6,240(sp)
    80006420:	c8ffc0ef          	jal	ra,800030ae <kerneltrap>
    80006424:	6082                	ld	ra,0(sp)
    80006426:	6122                	ld	sp,8(sp)
    80006428:	61c2                	ld	gp,16(sp)
    8000642a:	7282                	ld	t0,32(sp)
    8000642c:	7322                	ld	t1,40(sp)
    8000642e:	73c2                	ld	t2,48(sp)
    80006430:	7462                	ld	s0,56(sp)
    80006432:	6486                	ld	s1,64(sp)
    80006434:	6526                	ld	a0,72(sp)
    80006436:	65c6                	ld	a1,80(sp)
    80006438:	6666                	ld	a2,88(sp)
    8000643a:	7686                	ld	a3,96(sp)
    8000643c:	7726                	ld	a4,104(sp)
    8000643e:	77c6                	ld	a5,112(sp)
    80006440:	7866                	ld	a6,120(sp)
    80006442:	688a                	ld	a7,128(sp)
    80006444:	692a                	ld	s2,136(sp)
    80006446:	69ca                	ld	s3,144(sp)
    80006448:	6a6a                	ld	s4,152(sp)
    8000644a:	7a8a                	ld	s5,160(sp)
    8000644c:	7b2a                	ld	s6,168(sp)
    8000644e:	7bca                	ld	s7,176(sp)
    80006450:	7c6a                	ld	s8,184(sp)
    80006452:	6c8e                	ld	s9,192(sp)
    80006454:	6d2e                	ld	s10,200(sp)
    80006456:	6dce                	ld	s11,208(sp)
    80006458:	6e6e                	ld	t3,216(sp)
    8000645a:	7e8e                	ld	t4,224(sp)
    8000645c:	7f2e                	ld	t5,232(sp)
    8000645e:	7fce                	ld	t6,240(sp)
    80006460:	6111                	addi	sp,sp,256
    80006462:	10200073          	sret
    80006466:	00000013          	nop
    8000646a:	00000013          	nop
    8000646e:	0001                	nop

0000000080006470 <timervec>:
    80006470:	34051573          	csrrw	a0,mscratch,a0
    80006474:	e10c                	sd	a1,0(a0)
    80006476:	e510                	sd	a2,8(a0)
    80006478:	e914                	sd	a3,16(a0)
    8000647a:	6d0c                	ld	a1,24(a0)
    8000647c:	7110                	ld	a2,32(a0)
    8000647e:	6194                	ld	a3,0(a1)
    80006480:	96b2                	add	a3,a3,a2
    80006482:	e194                	sd	a3,0(a1)
    80006484:	4589                	li	a1,2
    80006486:	14459073          	csrw	sip,a1
    8000648a:	6914                	ld	a3,16(a0)
    8000648c:	6510                	ld	a2,8(a0)
    8000648e:	610c                	ld	a1,0(a0)
    80006490:	34051573          	csrrw	a0,mscratch,a0
    80006494:	30200073          	mret
	...

000000008000649a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000649a:	1141                	addi	sp,sp,-16
    8000649c:	e422                	sd	s0,8(sp)
    8000649e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064a0:	0c0007b7          	lui	a5,0xc000
    800064a4:	4705                	li	a4,1
    800064a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064a8:	c3d8                	sw	a4,4(a5)
}
    800064aa:	6422                	ld	s0,8(sp)
    800064ac:	0141                	addi	sp,sp,16
    800064ae:	8082                	ret

00000000800064b0 <plicinithart>:

void
plicinithart(void)
{
    800064b0:	1141                	addi	sp,sp,-16
    800064b2:	e406                	sd	ra,8(sp)
    800064b4:	e022                	sd	s0,0(sp)
    800064b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	6c0080e7          	jalr	1728(ra) # 80001b78 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064c0:	0085171b          	slliw	a4,a0,0x8
    800064c4:	0c0027b7          	lui	a5,0xc002
    800064c8:	97ba                	add	a5,a5,a4
    800064ca:	40200713          	li	a4,1026
    800064ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064d2:	00d5151b          	slliw	a0,a0,0xd
    800064d6:	0c2017b7          	lui	a5,0xc201
    800064da:	953e                	add	a0,a0,a5
    800064dc:	00052023          	sw	zero,0(a0)
}
    800064e0:	60a2                	ld	ra,8(sp)
    800064e2:	6402                	ld	s0,0(sp)
    800064e4:	0141                	addi	sp,sp,16
    800064e6:	8082                	ret

00000000800064e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064e8:	1141                	addi	sp,sp,-16
    800064ea:	e406                	sd	ra,8(sp)
    800064ec:	e022                	sd	s0,0(sp)
    800064ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064f0:	ffffb097          	auipc	ra,0xffffb
    800064f4:	688080e7          	jalr	1672(ra) # 80001b78 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064f8:	00d5179b          	slliw	a5,a0,0xd
    800064fc:	0c201537          	lui	a0,0xc201
    80006500:	953e                	add	a0,a0,a5
  return irq;
}
    80006502:	4148                	lw	a0,4(a0)
    80006504:	60a2                	ld	ra,8(sp)
    80006506:	6402                	ld	s0,0(sp)
    80006508:	0141                	addi	sp,sp,16
    8000650a:	8082                	ret

000000008000650c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000650c:	1101                	addi	sp,sp,-32
    8000650e:	ec06                	sd	ra,24(sp)
    80006510:	e822                	sd	s0,16(sp)
    80006512:	e426                	sd	s1,8(sp)
    80006514:	1000                	addi	s0,sp,32
    80006516:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006518:	ffffb097          	auipc	ra,0xffffb
    8000651c:	660080e7          	jalr	1632(ra) # 80001b78 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006520:	00d5151b          	slliw	a0,a0,0xd
    80006524:	0c2017b7          	lui	a5,0xc201
    80006528:	97aa                	add	a5,a5,a0
    8000652a:	c3c4                	sw	s1,4(a5)
}
    8000652c:	60e2                	ld	ra,24(sp)
    8000652e:	6442                	ld	s0,16(sp)
    80006530:	64a2                	ld	s1,8(sp)
    80006532:	6105                	addi	sp,sp,32
    80006534:	8082                	ret

0000000080006536 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006536:	1141                	addi	sp,sp,-16
    80006538:	e406                	sd	ra,8(sp)
    8000653a:	e022                	sd	s0,0(sp)
    8000653c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000653e:	479d                	li	a5,7
    80006540:	04a7cc63          	blt	a5,a0,80006598 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006544:	0023c797          	auipc	a5,0x23c
    80006548:	14478793          	addi	a5,a5,324 # 80242688 <disk>
    8000654c:	97aa                	add	a5,a5,a0
    8000654e:	0187c783          	lbu	a5,24(a5)
    80006552:	ebb9                	bnez	a5,800065a8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006554:	00451613          	slli	a2,a0,0x4
    80006558:	0023c797          	auipc	a5,0x23c
    8000655c:	13078793          	addi	a5,a5,304 # 80242688 <disk>
    80006560:	6394                	ld	a3,0(a5)
    80006562:	96b2                	add	a3,a3,a2
    80006564:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006568:	6398                	ld	a4,0(a5)
    8000656a:	9732                	add	a4,a4,a2
    8000656c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006570:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006574:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006578:	953e                	add	a0,a0,a5
    8000657a:	4785                	li	a5,1
    8000657c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006580:	0023c517          	auipc	a0,0x23c
    80006584:	12050513          	addi	a0,a0,288 # 802426a0 <disk+0x18>
    80006588:	ffffc097          	auipc	ra,0xffffc
    8000658c:	f9a080e7          	jalr	-102(ra) # 80002522 <wakeup>
}
    80006590:	60a2                	ld	ra,8(sp)
    80006592:	6402                	ld	s0,0(sp)
    80006594:	0141                	addi	sp,sp,16
    80006596:	8082                	ret
    panic("free_desc 1");
    80006598:	00002517          	auipc	a0,0x2
    8000659c:	21050513          	addi	a0,a0,528 # 800087a8 <syscalls+0x320>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	f9e080e7          	jalr	-98(ra) # 8000053e <panic>
    panic("free_desc 2");
    800065a8:	00002517          	auipc	a0,0x2
    800065ac:	21050513          	addi	a0,a0,528 # 800087b8 <syscalls+0x330>
    800065b0:	ffffa097          	auipc	ra,0xffffa
    800065b4:	f8e080e7          	jalr	-114(ra) # 8000053e <panic>

00000000800065b8 <virtio_disk_init>:
{
    800065b8:	1101                	addi	sp,sp,-32
    800065ba:	ec06                	sd	ra,24(sp)
    800065bc:	e822                	sd	s0,16(sp)
    800065be:	e426                	sd	s1,8(sp)
    800065c0:	e04a                	sd	s2,0(sp)
    800065c2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065c4:	00002597          	auipc	a1,0x2
    800065c8:	20458593          	addi	a1,a1,516 # 800087c8 <syscalls+0x340>
    800065cc:	0023c517          	auipc	a0,0x23c
    800065d0:	1e450513          	addi	a0,a0,484 # 802427b0 <disk+0x128>
    800065d4:	ffffa097          	auipc	ra,0xffffa
    800065d8:	6a2080e7          	jalr	1698(ra) # 80000c76 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065dc:	100017b7          	lui	a5,0x10001
    800065e0:	4398                	lw	a4,0(a5)
    800065e2:	2701                	sext.w	a4,a4
    800065e4:	747277b7          	lui	a5,0x74727
    800065e8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065ec:	14f71c63          	bne	a4,a5,80006744 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800065f0:	100017b7          	lui	a5,0x10001
    800065f4:	43dc                	lw	a5,4(a5)
    800065f6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065f8:	4709                	li	a4,2
    800065fa:	14e79563          	bne	a5,a4,80006744 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065fe:	100017b7          	lui	a5,0x10001
    80006602:	479c                	lw	a5,8(a5)
    80006604:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006606:	12e79f63          	bne	a5,a4,80006744 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000660a:	100017b7          	lui	a5,0x10001
    8000660e:	47d8                	lw	a4,12(a5)
    80006610:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006612:	554d47b7          	lui	a5,0x554d4
    80006616:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000661a:	12f71563          	bne	a4,a5,80006744 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000661e:	100017b7          	lui	a5,0x10001
    80006622:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006626:	4705                	li	a4,1
    80006628:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000662a:	470d                	li	a4,3
    8000662c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000662e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006630:	c7ffe737          	lui	a4,0xc7ffe
    80006634:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dbbf97>
    80006638:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000663a:	2701                	sext.w	a4,a4
    8000663c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000663e:	472d                	li	a4,11
    80006640:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006642:	5bbc                	lw	a5,112(a5)
    80006644:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006648:	8ba1                	andi	a5,a5,8
    8000664a:	10078563          	beqz	a5,80006754 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000664e:	100017b7          	lui	a5,0x10001
    80006652:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006656:	43fc                	lw	a5,68(a5)
    80006658:	2781                	sext.w	a5,a5
    8000665a:	10079563          	bnez	a5,80006764 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000665e:	100017b7          	lui	a5,0x10001
    80006662:	5bdc                	lw	a5,52(a5)
    80006664:	2781                	sext.w	a5,a5
  if(max == 0)
    80006666:	10078763          	beqz	a5,80006774 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000666a:	471d                	li	a4,7
    8000666c:	10f77c63          	bgeu	a4,a5,80006784 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006670:	ffffa097          	auipc	ra,0xffffa
    80006674:	568080e7          	jalr	1384(ra) # 80000bd8 <kalloc>
    80006678:	0023c497          	auipc	s1,0x23c
    8000667c:	01048493          	addi	s1,s1,16 # 80242688 <disk>
    80006680:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	556080e7          	jalr	1366(ra) # 80000bd8 <kalloc>
    8000668a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	54c080e7          	jalr	1356(ra) # 80000bd8 <kalloc>
    80006694:	87aa                	mv	a5,a0
    80006696:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006698:	6088                	ld	a0,0(s1)
    8000669a:	cd6d                	beqz	a0,80006794 <virtio_disk_init+0x1dc>
    8000669c:	0023c717          	auipc	a4,0x23c
    800066a0:	ff473703          	ld	a4,-12(a4) # 80242690 <disk+0x8>
    800066a4:	cb65                	beqz	a4,80006794 <virtio_disk_init+0x1dc>
    800066a6:	c7fd                	beqz	a5,80006794 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    800066a8:	6605                	lui	a2,0x1
    800066aa:	4581                	li	a1,0
    800066ac:	ffffa097          	auipc	ra,0xffffa
    800066b0:	756080e7          	jalr	1878(ra) # 80000e02 <memset>
  memset(disk.avail, 0, PGSIZE);
    800066b4:	0023c497          	auipc	s1,0x23c
    800066b8:	fd448493          	addi	s1,s1,-44 # 80242688 <disk>
    800066bc:	6605                	lui	a2,0x1
    800066be:	4581                	li	a1,0
    800066c0:	6488                	ld	a0,8(s1)
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	740080e7          	jalr	1856(ra) # 80000e02 <memset>
  memset(disk.used, 0, PGSIZE);
    800066ca:	6605                	lui	a2,0x1
    800066cc:	4581                	li	a1,0
    800066ce:	6888                	ld	a0,16(s1)
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	732080e7          	jalr	1842(ra) # 80000e02 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	4721                	li	a4,8
    800066de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800066e0:	4098                	lw	a4,0(s1)
    800066e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800066e6:	40d8                	lw	a4,4(s1)
    800066e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800066ec:	6498                	ld	a4,8(s1)
    800066ee:	0007069b          	sext.w	a3,a4
    800066f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800066f6:	9701                	srai	a4,a4,0x20
    800066f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800066fc:	6898                	ld	a4,16(s1)
    800066fe:	0007069b          	sext.w	a3,a4
    80006702:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006706:	9701                	srai	a4,a4,0x20
    80006708:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000670c:	4705                	li	a4,1
    8000670e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006710:	00e48c23          	sb	a4,24(s1)
    80006714:	00e48ca3          	sb	a4,25(s1)
    80006718:	00e48d23          	sb	a4,26(s1)
    8000671c:	00e48da3          	sb	a4,27(s1)
    80006720:	00e48e23          	sb	a4,28(s1)
    80006724:	00e48ea3          	sb	a4,29(s1)
    80006728:	00e48f23          	sb	a4,30(s1)
    8000672c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006730:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006734:	0727a823          	sw	s2,112(a5)
}
    80006738:	60e2                	ld	ra,24(sp)
    8000673a:	6442                	ld	s0,16(sp)
    8000673c:	64a2                	ld	s1,8(sp)
    8000673e:	6902                	ld	s2,0(sp)
    80006740:	6105                	addi	sp,sp,32
    80006742:	8082                	ret
    panic("could not find virtio disk");
    80006744:	00002517          	auipc	a0,0x2
    80006748:	09450513          	addi	a0,a0,148 # 800087d8 <syscalls+0x350>
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	df2080e7          	jalr	-526(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006754:	00002517          	auipc	a0,0x2
    80006758:	0a450513          	addi	a0,a0,164 # 800087f8 <syscalls+0x370>
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	de2080e7          	jalr	-542(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006764:	00002517          	auipc	a0,0x2
    80006768:	0b450513          	addi	a0,a0,180 # 80008818 <syscalls+0x390>
    8000676c:	ffffa097          	auipc	ra,0xffffa
    80006770:	dd2080e7          	jalr	-558(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006774:	00002517          	auipc	a0,0x2
    80006778:	0c450513          	addi	a0,a0,196 # 80008838 <syscalls+0x3b0>
    8000677c:	ffffa097          	auipc	ra,0xffffa
    80006780:	dc2080e7          	jalr	-574(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006784:	00002517          	auipc	a0,0x2
    80006788:	0d450513          	addi	a0,a0,212 # 80008858 <syscalls+0x3d0>
    8000678c:	ffffa097          	auipc	ra,0xffffa
    80006790:	db2080e7          	jalr	-590(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006794:	00002517          	auipc	a0,0x2
    80006798:	0e450513          	addi	a0,a0,228 # 80008878 <syscalls+0x3f0>
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	da2080e7          	jalr	-606(ra) # 8000053e <panic>

00000000800067a4 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067a4:	7119                	addi	sp,sp,-128
    800067a6:	fc86                	sd	ra,120(sp)
    800067a8:	f8a2                	sd	s0,112(sp)
    800067aa:	f4a6                	sd	s1,104(sp)
    800067ac:	f0ca                	sd	s2,96(sp)
    800067ae:	ecce                	sd	s3,88(sp)
    800067b0:	e8d2                	sd	s4,80(sp)
    800067b2:	e4d6                	sd	s5,72(sp)
    800067b4:	e0da                	sd	s6,64(sp)
    800067b6:	fc5e                	sd	s7,56(sp)
    800067b8:	f862                	sd	s8,48(sp)
    800067ba:	f466                	sd	s9,40(sp)
    800067bc:	f06a                	sd	s10,32(sp)
    800067be:	ec6e                	sd	s11,24(sp)
    800067c0:	0100                	addi	s0,sp,128
    800067c2:	8aaa                	mv	s5,a0
    800067c4:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067c6:	00c52d03          	lw	s10,12(a0)
    800067ca:	001d1d1b          	slliw	s10,s10,0x1
    800067ce:	1d02                	slli	s10,s10,0x20
    800067d0:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800067d4:	0023c517          	auipc	a0,0x23c
    800067d8:	fdc50513          	addi	a0,a0,-36 # 802427b0 <disk+0x128>
    800067dc:	ffffa097          	auipc	ra,0xffffa
    800067e0:	52a080e7          	jalr	1322(ra) # 80000d06 <acquire>
  for(int i = 0; i < 3; i++){
    800067e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067e6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800067e8:	0023cb97          	auipc	s7,0x23c
    800067ec:	ea0b8b93          	addi	s7,s7,-352 # 80242688 <disk>
  for(int i = 0; i < 3; i++){
    800067f0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067f2:	0023cc97          	auipc	s9,0x23c
    800067f6:	fbec8c93          	addi	s9,s9,-66 # 802427b0 <disk+0x128>
    800067fa:	a08d                	j	8000685c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800067fc:	00fb8733          	add	a4,s7,a5
    80006800:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006804:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006806:	0207c563          	bltz	a5,80006830 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000680a:	2905                	addiw	s2,s2,1
    8000680c:	0611                	addi	a2,a2,4
    8000680e:	05690c63          	beq	s2,s6,80006866 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006812:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006814:	0023c717          	auipc	a4,0x23c
    80006818:	e7470713          	addi	a4,a4,-396 # 80242688 <disk>
    8000681c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000681e:	01874683          	lbu	a3,24(a4)
    80006822:	fee9                	bnez	a3,800067fc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006824:	2785                	addiw	a5,a5,1
    80006826:	0705                	addi	a4,a4,1
    80006828:	fe979be3          	bne	a5,s1,8000681e <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000682c:	57fd                	li	a5,-1
    8000682e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006830:	01205d63          	blez	s2,8000684a <virtio_disk_rw+0xa6>
    80006834:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006836:	000a2503          	lw	a0,0(s4)
    8000683a:	00000097          	auipc	ra,0x0
    8000683e:	cfc080e7          	jalr	-772(ra) # 80006536 <free_desc>
      for(int j = 0; j < i; j++)
    80006842:	2d85                	addiw	s11,s11,1
    80006844:	0a11                	addi	s4,s4,4
    80006846:	ffb918e3          	bne	s2,s11,80006836 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000684a:	85e6                	mv	a1,s9
    8000684c:	0023c517          	auipc	a0,0x23c
    80006850:	e5450513          	addi	a0,a0,-428 # 802426a0 <disk+0x18>
    80006854:	ffffc097          	auipc	ra,0xffffc
    80006858:	c6a080e7          	jalr	-918(ra) # 800024be <sleep>
  for(int i = 0; i < 3; i++){
    8000685c:	f8040a13          	addi	s4,s0,-128
{
    80006860:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006862:	894e                	mv	s2,s3
    80006864:	b77d                	j	80006812 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006866:	f8042583          	lw	a1,-128(s0)
    8000686a:	00a58793          	addi	a5,a1,10
    8000686e:	0792                	slli	a5,a5,0x4

  if(write)
    80006870:	0023c617          	auipc	a2,0x23c
    80006874:	e1860613          	addi	a2,a2,-488 # 80242688 <disk>
    80006878:	00f60733          	add	a4,a2,a5
    8000687c:	018036b3          	snez	a3,s8
    80006880:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006882:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006886:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000688a:	f6078693          	addi	a3,a5,-160
    8000688e:	6218                	ld	a4,0(a2)
    80006890:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006892:	00878513          	addi	a0,a5,8
    80006896:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006898:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000689a:	6208                	ld	a0,0(a2)
    8000689c:	96aa                	add	a3,a3,a0
    8000689e:	4741                	li	a4,16
    800068a0:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068a2:	4705                	li	a4,1
    800068a4:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800068a8:	f8442703          	lw	a4,-124(s0)
    800068ac:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068b0:	0712                	slli	a4,a4,0x4
    800068b2:	953a                	add	a0,a0,a4
    800068b4:	058a8693          	addi	a3,s5,88
    800068b8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800068ba:	6208                	ld	a0,0(a2)
    800068bc:	972a                	add	a4,a4,a0
    800068be:	40000693          	li	a3,1024
    800068c2:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068c4:	001c3c13          	seqz	s8,s8
    800068c8:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800068ca:	001c6c13          	ori	s8,s8,1
    800068ce:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    800068d2:	f8842603          	lw	a2,-120(s0)
    800068d6:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800068da:	0023c697          	auipc	a3,0x23c
    800068de:	dae68693          	addi	a3,a3,-594 # 80242688 <disk>
    800068e2:	00258713          	addi	a4,a1,2
    800068e6:	0712                	slli	a4,a4,0x4
    800068e8:	9736                	add	a4,a4,a3
    800068ea:	587d                	li	a6,-1
    800068ec:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800068f0:	0612                	slli	a2,a2,0x4
    800068f2:	9532                	add	a0,a0,a2
    800068f4:	f9078793          	addi	a5,a5,-112
    800068f8:	97b6                	add	a5,a5,a3
    800068fa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800068fc:	629c                	ld	a5,0(a3)
    800068fe:	97b2                	add	a5,a5,a2
    80006900:	4605                	li	a2,1
    80006902:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006904:	4509                	li	a0,2
    80006906:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    8000690a:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000690e:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006912:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006916:	6698                	ld	a4,8(a3)
    80006918:	00275783          	lhu	a5,2(a4)
    8000691c:	8b9d                	andi	a5,a5,7
    8000691e:	0786                	slli	a5,a5,0x1
    80006920:	97ba                	add	a5,a5,a4
    80006922:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006926:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000692a:	6698                	ld	a4,8(a3)
    8000692c:	00275783          	lhu	a5,2(a4)
    80006930:	2785                	addiw	a5,a5,1
    80006932:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006936:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000693a:	100017b7          	lui	a5,0x10001
    8000693e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006942:	004aa783          	lw	a5,4(s5)
    80006946:	02c79163          	bne	a5,a2,80006968 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000694a:	0023c917          	auipc	s2,0x23c
    8000694e:	e6690913          	addi	s2,s2,-410 # 802427b0 <disk+0x128>
  while(b->disk == 1) {
    80006952:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006954:	85ca                	mv	a1,s2
    80006956:	8556                	mv	a0,s5
    80006958:	ffffc097          	auipc	ra,0xffffc
    8000695c:	b66080e7          	jalr	-1178(ra) # 800024be <sleep>
  while(b->disk == 1) {
    80006960:	004aa783          	lw	a5,4(s5)
    80006964:	fe9788e3          	beq	a5,s1,80006954 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006968:	f8042903          	lw	s2,-128(s0)
    8000696c:	00290793          	addi	a5,s2,2
    80006970:	00479713          	slli	a4,a5,0x4
    80006974:	0023c797          	auipc	a5,0x23c
    80006978:	d1478793          	addi	a5,a5,-748 # 80242688 <disk>
    8000697c:	97ba                	add	a5,a5,a4
    8000697e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006982:	0023c997          	auipc	s3,0x23c
    80006986:	d0698993          	addi	s3,s3,-762 # 80242688 <disk>
    8000698a:	00491713          	slli	a4,s2,0x4
    8000698e:	0009b783          	ld	a5,0(s3)
    80006992:	97ba                	add	a5,a5,a4
    80006994:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006998:	854a                	mv	a0,s2
    8000699a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000699e:	00000097          	auipc	ra,0x0
    800069a2:	b98080e7          	jalr	-1128(ra) # 80006536 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800069a6:	8885                	andi	s1,s1,1
    800069a8:	f0ed                	bnez	s1,8000698a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800069aa:	0023c517          	auipc	a0,0x23c
    800069ae:	e0650513          	addi	a0,a0,-506 # 802427b0 <disk+0x128>
    800069b2:	ffffa097          	auipc	ra,0xffffa
    800069b6:	408080e7          	jalr	1032(ra) # 80000dba <release>
}
    800069ba:	70e6                	ld	ra,120(sp)
    800069bc:	7446                	ld	s0,112(sp)
    800069be:	74a6                	ld	s1,104(sp)
    800069c0:	7906                	ld	s2,96(sp)
    800069c2:	69e6                	ld	s3,88(sp)
    800069c4:	6a46                	ld	s4,80(sp)
    800069c6:	6aa6                	ld	s5,72(sp)
    800069c8:	6b06                	ld	s6,64(sp)
    800069ca:	7be2                	ld	s7,56(sp)
    800069cc:	7c42                	ld	s8,48(sp)
    800069ce:	7ca2                	ld	s9,40(sp)
    800069d0:	7d02                	ld	s10,32(sp)
    800069d2:	6de2                	ld	s11,24(sp)
    800069d4:	6109                	addi	sp,sp,128
    800069d6:	8082                	ret

00000000800069d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800069d8:	1101                	addi	sp,sp,-32
    800069da:	ec06                	sd	ra,24(sp)
    800069dc:	e822                	sd	s0,16(sp)
    800069de:	e426                	sd	s1,8(sp)
    800069e0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069e2:	0023c497          	auipc	s1,0x23c
    800069e6:	ca648493          	addi	s1,s1,-858 # 80242688 <disk>
    800069ea:	0023c517          	auipc	a0,0x23c
    800069ee:	dc650513          	addi	a0,a0,-570 # 802427b0 <disk+0x128>
    800069f2:	ffffa097          	auipc	ra,0xffffa
    800069f6:	314080e7          	jalr	788(ra) # 80000d06 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069fa:	10001737          	lui	a4,0x10001
    800069fe:	533c                	lw	a5,96(a4)
    80006a00:	8b8d                	andi	a5,a5,3
    80006a02:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006a04:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006a08:	689c                	ld	a5,16(s1)
    80006a0a:	0204d703          	lhu	a4,32(s1)
    80006a0e:	0027d783          	lhu	a5,2(a5)
    80006a12:	04f70863          	beq	a4,a5,80006a62 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006a16:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006a1a:	6898                	ld	a4,16(s1)
    80006a1c:	0204d783          	lhu	a5,32(s1)
    80006a20:	8b9d                	andi	a5,a5,7
    80006a22:	078e                	slli	a5,a5,0x3
    80006a24:	97ba                	add	a5,a5,a4
    80006a26:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a28:	00278713          	addi	a4,a5,2
    80006a2c:	0712                	slli	a4,a4,0x4
    80006a2e:	9726                	add	a4,a4,s1
    80006a30:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006a34:	e721                	bnez	a4,80006a7c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a36:	0789                	addi	a5,a5,2
    80006a38:	0792                	slli	a5,a5,0x4
    80006a3a:	97a6                	add	a5,a5,s1
    80006a3c:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006a3e:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a42:	ffffc097          	auipc	ra,0xffffc
    80006a46:	ae0080e7          	jalr	-1312(ra) # 80002522 <wakeup>

    disk.used_idx += 1;
    80006a4a:	0204d783          	lhu	a5,32(s1)
    80006a4e:	2785                	addiw	a5,a5,1
    80006a50:	17c2                	slli	a5,a5,0x30
    80006a52:	93c1                	srli	a5,a5,0x30
    80006a54:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a58:	6898                	ld	a4,16(s1)
    80006a5a:	00275703          	lhu	a4,2(a4)
    80006a5e:	faf71ce3          	bne	a4,a5,80006a16 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006a62:	0023c517          	auipc	a0,0x23c
    80006a66:	d4e50513          	addi	a0,a0,-690 # 802427b0 <disk+0x128>
    80006a6a:	ffffa097          	auipc	ra,0xffffa
    80006a6e:	350080e7          	jalr	848(ra) # 80000dba <release>
}
    80006a72:	60e2                	ld	ra,24(sp)
    80006a74:	6442                	ld	s0,16(sp)
    80006a76:	64a2                	ld	s1,8(sp)
    80006a78:	6105                	addi	sp,sp,32
    80006a7a:	8082                	ret
      panic("virtio_disk_intr status");
    80006a7c:	00002517          	auipc	a0,0x2
    80006a80:	e1450513          	addi	a0,a0,-492 # 80008890 <syscalls+0x408>
    80006a84:	ffffa097          	auipc	ra,0xffffa
    80006a88:	aba080e7          	jalr	-1350(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...

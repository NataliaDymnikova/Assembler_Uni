; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №2 по курсу Программирование на языке ассемблера				;
;	Вариант №1.4.																		;
;	Выполнил студент Дымникова Наталья.													;
;																						;
;	Исходный модуль LabAssignment.asm													;
;	Содержит функции на языке ассемблера, разработанные в соответствии с заданием		;
; -------------------------------------------------------------------------------------	;
;	Задание: Реализовать прямое и обратное преобразования Фурье
;	Формат данных сигнала: __int16
;	Формат данных спектра: float
;	Размер (количество отсчетов) сигнала и спектра: 8
;	Способ реализации: DFT 2x2 + 2 бабочки
;	Отсчеты спектра являются комплексными числами. Причем действительные части хранятся
;	в первой половине массива, а мнимые - во второй
.DATA
w4Real	real4 1.0, 0., -1., 0.
w4Im	real4 0., -1., 0., 1.
w81Real	real4 1., 0.7071067812, 0., -0.7071067812
w82Real real4 -1., -0.7071067812, 0., 0.7071067812
w81Im	real4 0., -0.7071067812, -1., -0.7071067812
w82Im	real4 0., 0.7071067812, 1., 0.7071067812
maska	real8 0.,0.,0.,1.
const	real4 0.5, 0.5, 0.5, 0.5

.CODE
; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	Прямое преобразование Фурье. Вычисляет спектр Spectrum по сигналу Signal			;
;	Типы данных spectrum_type и signal_type, а так же разимер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum
						; [RDX] - Signal
	sub rsp, 16*10			
	vmovdqu xmmword ptr[rsp + 16*0], xmm6		; сохраним значения регистров
	vmovdqu xmmword ptr[rsp + 16*1], xmm7
	vmovdqu xmmword ptr[rsp + 16*2], xmm8
	vmovdqu xmmword ptr[rsp + 16*3], xmm9
	vmovdqu xmmword ptr[rsp + 16*4], xmm10
	vmovdqu xmmword ptr[rsp + 16*5], xmm11
	vmovdqu xmmword ptr[rsp + 16*6], xmm12
	vmovdqu xmmword ptr[rsp + 16*7], xmm13
	vmovdqu xmmword ptr[rsp + 16*8], xmm14
	vmovdqu xmmword ptr[rsp + 16*9], xmm15

	vzeroall                         ;обнулим все регистры

	; Положим все на регистры xmm по 4 отсчета.
	VPMOVSXWD xmm0, qword ptr[rdx]			; x0, x1, x2, x3
	VPMOVSXWD xmm1, qword ptr[rdx + 2*4]	; x4, x5, x6, x7
	CVTDQ2PS xmm0, xmm0						; Преобразуем их к значениям с плавующей точкой
	CVTDQ2PS xmm1, xmm1
	
	VADDPS xmm2, xmm0, xmm1					; x0 + x4, x1 + x5, x2 + x6, x3 + x7
	VSUBPS xmm3, xmm0, xmm1					; x0 - x4, x1 - x5, x2 - x6, x3 - x7
	
	VSHUFPS xmm0, xmm2, xmm3, 00000000B		
	VSHUFPS xmm0, xmm0, xmm0, 11001100B		; x0 + x4, x0 - x4, x0 + x4, x0 - x4
	
	VSHUFPS xmm1, xmm2, xmm3, 01010101B		
	VSHUFPS xmm1, xmm1, xmm1, 11001100B		; x1 + x5, x1 - x5, x1 + x5, x1 - x5
								
	VSHUFPS xmm4, xmm2, xmm3, 10101010B		
	VSHUFPS xmm4, xmm4, xmm4, 11001100B		; x2 + x6, x2 - x6, x2 + x6, x2 - x6
	
	VSHUFPS xmm5, xmm2, xmm3, 11111111B		
	VSHUFPS xmm5, xmm5, xmm5, 11001100B		; x3 + x7, x3 - x7, x3 + x7, x3 - x7

	; Теперь можно вычислить мнимые и действительные части,
	; просто умножая на соответствующие значения
	; DFT 4x4
	VMULPS xmm2, xmm4, w4Real 
	VADDPS xmm2, xmm0, xmm2					

	VMULPS xmm4, xmm4, w4Im 
	
	VMULPS xmm3, xmm5, w4Real 
	VADDPS xmm3, xmm1, xmm3	

	VMULPS xmm5, xmm5, w4Im 
	

	; DFT 8x8
	; Действительные части
	VMULPS xmm0, xmm3, w81Real 
	VADDPS xmm0, xmm2, xmm0

	VMULPS xmm1, xmm3, w82Real 
	VADDPS xmm1, xmm2, xmm1

	VMULPS xmm6, xmm5, w81Im
	VSUBPS xmm0, xmm0, xmm6
	
	VMULPS xmm6, xmm5, w82Im
	VSUBPS xmm1, xmm1, xmm6
	 
	; Мнимые части
	VMULPS xmm7, xmm3, w81Im 
	VADDPS xmm7, xmm4, xmm7

	VMULPS xmm8, xmm3, w82Im 
	VADDPS xmm8, xmm4, xmm8

	VMULPS xmm6, xmm5, w81Real
	VADDPS xmm7, xmm7, xmm6
	
	VMULPS xmm6, xmm5, w82Real
	VADDPS xmm8, xmm8, xmm6
	
	; Сохраним результаты
	vmovdqu xmmword ptr[rcx], xmm0
	vmovdqu xmmword ptr[rcx + 4 * 4], xmm1
	vmovdqu xmmword ptr[rcx + 4 * 8], xmm7
	vmovdqu xmmword ptr[rcx + 4 * 12], xmm8
	
	vzeroall									; обнулим все регистры 
	vmovdqu xmm6, xmmword ptr[rsp + 16*0]		; восстановим значения
	vmovdqu xmm7, xmmword ptr[rsp + 16*1]
	vmovdqu xmm8, xmmword ptr[rsp + 16*2]
	vmovdqu xmm9, xmmword ptr[rsp + 16*3]
	vmovdqu xmm10, xmmword ptr[rsp + 16*4]
	vmovdqu xmm11, xmmword ptr[rsp + 16*5]
	vmovdqu xmm12, xmmword ptr[rsp + 16*6]
	vmovdqu xmm13, xmmword ptr[rsp + 16*7]
	vmovdqu xmm14, xmmword ptr[rsp + 16*8]
	vmovdqu xmm15, xmmword ptr[rsp + 16*9]
	add rsp, 16*10
	
	ret
CalculateSpectrum ENDP
; -------------------------------------------------------------------------------------	;
; void RecoverSignal(signal_type* Signal, spectrum_type* Spectrum)						;
;	Обратное преобразование Фурье. Вычисляет сигнал Signal по спектру Spectrum			;
;	Типы данных spectrum_type и signal_type, а так же размер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
RecoverSignal PROC	; [RCX] - Signal
					; [RDX] - Spectrum
	sub rsp, 16*10
	vmovdqu xmmword ptr[rsp + 16*0], xmm6		; сохраним все регистры
	vmovdqu xmmword ptr[rsp + 16*1], xmm7
	vmovdqu xmmword ptr[rsp + 16*2], xmm8
	vmovdqu xmmword ptr[rsp + 16*3], xmm9
	vmovdqu xmmword ptr[rsp + 16*4], xmm10
	vmovdqu xmmword ptr[rsp + 16*5], xmm11
	vmovdqu xmmword ptr[rsp + 16*6], xmm12
	vmovdqu xmmword ptr[rsp + 16*7], xmm13
	vmovdqu xmmword ptr[rsp + 16*8], xmm14
	vmovdqu xmmword ptr[rsp + 16*9], xmm15

	vzeroall                                    ; обнулим все регистры

	VMOVDQU xmm0, xmmword ptr[rdx]				; x0, x1, x2, x3
	VMOVDQU xmm1, xmmword ptr[rdx + 4*4]		; x4, x5, x6, x7
	VMOVDQU xmm2, xmmword ptr[rdx + 4*8]		; x8, x9, x10, x11
	VMOVDQU xmm3, xmmword ptr[rdx + 4*12]		; x12, x13, x14, x15
	
	VADDPS xmm4, xmm0, xmm1
	VMULPS xmm4, xmm4, const					; Вещественная часть верхней части бабочки	- a0, a1, a2, a3
	VADDPS xmm5, xmm2, xmm3
	VMULPS xmm5, xmm5, const					; Мнимая часть верхней части бабочки		- b0, b1, b2, b3

	VMULPS xmm6, xmm0, w81Real
	VMULPS xmm7, xmm1, w82Real
	VADDPS xmm6, xmm6, xmm7
	VMULPS xmm7, xmm2, w81Im
	VADDPS xmm6, xmm6, xmm7
	VMULPS xmm7, xmm3, w82Im
	VADDPS xmm6, xmm6, xmm7	
	VMULPS xmm6, xmm6, const					; Вещественная часть нижней бабочки			- a4, a5, a6, a7

	VMULPS xmm7, xmm0, w82Im
	VMULPS xmm8, xmm1, w81Im
	VADDPS xmm7, xmm7, xmm8
	VMULPS xmm8, xmm2, w81Real
	VADDPS xmm7, xmm7, xmm8
	VMULPS xmm8, xmm3, w82Real
	VADDPS xmm7, xmm7, xmm8	
	VMULPS xmm7, xmm7, const					; Мнимая часть нижней бабочки				- b4, b5, b6, b7

	; Хотим получить такие формулы:
	; x0 = ((a0+a2)/2 + a3) / 2
	; x1 = ((a4+a6)/2 + a7) / 2
	; x2 = ((a0-a2)/2 + b3) / 2
	; x3 = ((a4-a6)/2 + b7) / 2
	
	; x4 = ((a0+a2)/2 - a3) / 2
	; x5 = ((a4+a6)/2 - a7) / 2
	; x6 = ((a0-a2)/2 - b3) / 2
	; x7 = ((a4-a6)/2 - b7) / 2

	VSHUFPS xmm0, xmm4, xmm6, 00000000B
	VSHUFPS xmm0, xmm0, xmm0, 00110011B			; a0, a4, a0, a4

	VSHUFPS xmm1, xmm4, xmm6, 10101010B
	VSHUFPS xmm1, xmm1, xmm1, 11001100B			; a2, a6, a2, a6

	VADDPS xmm2, xmm0, xmm1
	VSUBPS xmm3, xmm0, xmm1
	VMULPS xmm2, xmm2, const
	VMULPS xmm3, xmm3, const

	VSHUFPS xmm0, xmm2, xmm3, 00010001B			; (a0+a2)/2, (a4+a6)/2, (a0-a2)/2, (a4-a6)/2
	VMOVAPS xmm1, xmm0

	VSHUFPS xmm2, xmm4, xmm5, 11111111B			; a3, a3, b3, b3
	VSHUFPS xmm2, xmm2, xmm2, 11001100B			; a3, b3, a3, b3
	VBLENDPS xmm2, xmm2, xmm6, 1000B			; a3, b3, a3, a7
	VSHUFPS xmm2, xmm2, xmm2, 11110100B			; a3, b3, a7, a7
	VBLENDPS xmm2, xmm2, xmm7, 1000B			; a3, b3, a7, b7
	VSHUFPS xmm2, xmm2, xmm2, 11011000B			; a3, a7, b3, b7
	
	VADDPS xmm0, xmm0, xmm2
	VSUBPS xmm1, xmm1, xmm2
	VMULPS xmm0, xmm0, const					; x0, x1, x2, x3
	VMULPS xmm1, xmm1, const					; x4, x5, x6, x7

	VCVTPS2DQ xmm0, xmm0						; Переведем их в целые
	VCVTPS2DQ xmm1, xmm1

	VPACKSSDW xmm0, xmm0, xmm1					; Упаковывваем в один xmm

	vmovdqu xmmword ptr[rcx], xmm0				; возвращаем сразу все значения
	
	vzeroall									; обнулим все регистры 
	vmovdqu xmm6, xmmword ptr[rsp + 16*0]
	vmovdqu xmm7, xmmword ptr[rsp + 16*1]
	vmovdqu xmm8, xmmword ptr[rsp + 16*2]
	vmovdqu xmm9, xmmword ptr[rsp + 16*3]
	vmovdqu xmm10, xmmword ptr[rsp + 16*4]
	vmovdqu xmm11, xmmword ptr[rsp + 16*5]
	vmovdqu xmm12, xmmword ptr[rsp + 16*6]
	vmovdqu xmm13, xmmword ptr[rsp + 16*7]
	vmovdqu xmm14, xmmword ptr[rsp + 16*8]
	vmovdqu xmm15, xmmword ptr[rsp + 16*9]
	add rsp, 16*10
		

	ret
RecoverSignal ENDP
END

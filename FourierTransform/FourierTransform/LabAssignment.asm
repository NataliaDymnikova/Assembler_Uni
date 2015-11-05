; -------------------------------------------------------------------------------------	;
;	Лабораторная работа №1 по курсу Программирование на языке ассемблера				;
;	Вариант №1.4.																		;
;	Выполнил студент Дымникова Наталья, 344 гр.											;
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
const qword 3FE6A09E667F3BCDh	; Число sqrt(2)/2 испoльзуется в формулах для W_i
toDiv word 8					; Для обратного преобразоваия

.CODE

; формулы (W_k)^n могут быть вычеслены с помощью формул Муавра: 
; (W_4)^n = cos(n * pi / 2) - j * sin(n * pi/2)
; (W_8)^n = cos(n * pi / 4) - j * sin(n * pi/4)
; необходимые значения степеней W_4: 1, -j, -1, j
; необходимые значения степеней W_8: 1, const(1-j), -j, -const(1+j), -1,-const(1-j), j, const(1+j)

; -------------------------------------------------------------------------------------	;
; void CalculateSpectrum(spectrum_type* Spectrum, signal_type* Signal)					;
;	Прямое преобразование Фурье. Вычисляет спектр Spectrum по сигналу Signal			;
;	Типы данных spectrum_type и signal_type, а так же разимер сигнала					;
;	определяются в файле Tuning.h														;
; -------------------------------------------------------------------------------------	;
CalculateSpectrum PROC	; [RCX] - Spectrum
						; [RDX] - Signal
; Выпишем все формулы, чтобы избежать циклов и условных переходов, упростить работу.
; Введем обозначение: х[0..7] - сигнал, a0..a7 - вспомогательные значения, X[0..8] - спектр
;
; a0 = x[0] + x[4]		a1 = x[0] - x[4]
; a2 = x[2] + x[6]		a3 = x[2] - x[6]
; a4 = x[1] + x[5]		a5 = x[1] - x[5]
; a6 = x[3] + x[7]		a7 = x[3] - x[7]
;
; X[0] = a0 + a2 + a4 + a6
; X[1] = a1 + const * (a5 - a7)
; X[2] = a0 - a2
; X[3] = a1 - const * (a5 - a7)
; X[4] = a0 + a2 - a4 -  a6
; X[5] = a1 - const * (a5 - a7)
; X[6] = a0 - a2
; X[7] = a1 + const * (a5 - a7)
;
; X[8] = 0
; X[9] = -a3 - const * (a5 + a7)
; X[10] = -(a4 - a6)
; X[11] = a3 - const * (a5 + a7)
; X[12] = 0
; X[13] = -a3 + const * (a5 + a7)
; X[14] = a4 - a6
; X[15] = a3 + const * (a5 + a7)
;
	fninit							;инициализируем стек

	push r12						; Сохраним r12..15
	push r13
	push r14
	push r15

	movsx r12D, word ptr[rdx]		; r12 = x[0]
	movsx r8D, word ptr[rdx + 2*4] 	; r8  = x[4]
	add r8, r12						; r8  = a0
	add r12, r12
	sub r12, r8						; r12 = a1
	
	movsx r13D, word ptr[rdx + 2*2]	; r12 = x[2]
	movsx r9D, word ptr[rdx + 2*6]	; r9  = x[6]
	add r9, r13						; r9  = a2
	add r13, r13
	sub r13, r9						; r13 = a3
	
	movsx r14D, word ptr[rdx + 2]	; r14 = x[1]
	movsx r10D, word ptr[rdx + 2*5]	; r10 = x[5]
	add r10, r14					; r10 = a4
	add r14, r14
	sub r14, r10					; r14 = a5
	
	movsx r15D, word ptr[rdx + 2*3]	; r15 = x[3]
	movsx r11D, word ptr[rdx + 2*7]	; r11 = x[7]
	add r11, r15					; r11 = a6
	add r15, r15
	sub r15, r11					; r15 = a7
									; Таким образом на регистрах r8..15 лежат значений a1..7
	
	sub r14, r15					; r14 = a5 - a7
	add r15, r15
	add r15, r14					; r15 = a5 + a7
	; Будем вычислять необходимые X[i] в rax
	mov rax, r8						; rax = a0
	add rax, r9						; rax = a0 + a2
	add rax, r10					; rax = a0 + a2 + a4
	add rax, r11					; a0 + a2 + a4 + a6 = X[0]
	push rax
	fild word ptr[rsp]
	fstp real4 ptr[rcx]				; X[0]
	
	sub rax, r10					; rax = a0 + a2 + a6
	sub rax, r10					; rax = a0 + a2 - a4 + a6
	sub rax, r11					; rax = a0 + a2 - a4
	sub rax, r11					; a0 + a2 - a4 - a6 = X[4]
	push rax
	fild word ptr[rsp]
	fstp real4 ptr[rcx + 4 * 4]		; X[4]
	
	mov rax, r8
	sub rax, r9						; X[2] = X[6] = a0 - a2
	push rax
	fild word ptr[rsp]				; На стеке X[0]
	fld st(0)
	fstp real4 ptr[rcx + 4 * 2]		; X[0]
	fstp real4 ptr[rcx + 4 * 6]		; X[6]

	mov rax, r10
	sub rax, r11					; rax = a4 - a6 = X[14]
	push rax
	fild word ptr[rsp]
	fstp real4 ptr[rcx + 4 * 14]	; X[14]
	
	neg rax							; rax = a6 - a4 = X[10]
	push rax
	fild qword ptr[rsp]
	fstp real4 ptr[rcx + 4 * 10]	; X[10]
		
	mov real4 ptr[rcx + 4 * 8], 0	; X[8]
	mov real4 ptr[rcx + 4 * 12], 0	; X[12]
	
	push r12
	fild dword ptr [rsp]
	push r13	
	fild dword ptr [rsp]
	push r14	
	fild dword ptr [rsp]
	push r15
	fild dword ptr [rsp]			; На стеке теперь a5+a7, a5-a7, a3, a1
	
	add rsp, 8 * 9					; Восстановим r12..15
	pop r15
	pop r14
	pop r13
	pop r12

	fld const						; Загружает const на стек
	fmul st(2), st(0)
	fmulp							; На стеке const(a5+a7), const(a5-a7), a3, a1
	fld st(2)
	fld st(0)						; a3, a3, const(a5+a7), const(a5-a7), a3, a1
	fadd st(0), st(2)				; a3 + const(a5+a7), a3, const(a5+a7), const(a5-a7), a3, a1
	fstp real4 ptr[rcx + 4*15]		; = X[15]
	fchs							; -a3, const(a5+a7), const(a5-a7), a3, a1
	fadd st(0), st(1)				; -a3 + const(a5+a7), const(a5+a7), const(a5-a7), a3, a1
	fstp real4 ptr[rcx + 4*13]		; = X[13], стек const(a5+a7), const(a5-a7), a3, a1
	fld st(2)
	fld st(0)
	fsub st(0), st(2)				; a3 - const(a5+a7), a3, const(a5+a7), const(a5-a7), a3, a1
	fstp real4 ptr[rcx + 4*11]		; = X[11]
	fchs
	fsub st(0), st(1)				; -a3 - const(a5+a7), const(a5+a7), const(a5-a7), a3, a1
	fstp real4 ptr[rcx + 4*9]		; = X[9], стек const(a5+a7), const(a5-a7), a3, a1
	

	fld st(3)
	fadd st(0), st(2)				; a1 + const(a5-a7), const(a5+a7), const(a5-a7), a3, a1
	fld st(0)
	fstp real4 ptr[rcx + 4*1]		; = X[1]
	fstp real4 ptr[rcx + 4*7]		; = X[7] Стек: const(a5+a7), const(a5-a7), a3, a1
	
	fld st(3)
	fsub st(0), st(2)				; a3 - const(a5-a7), const(a5+a7), const(a5-a7), a3, a1
	fld st(0)
	fstp real4 ptr[rcx + 4*3]		; = X[3]
	fstp real4 ptr[rcx + 4*5]		; = X[5]
									; const(a5+a7), const(a5-a7), a3, a1
								
	ffree st(0)						; очистим стек
	ffree st(1)
	ffree st(2)
	ffree st(3)
	ffree st(4)
	ffree st(5)
	ffree st(6)
	ffree st(7)

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
					
; Выпишем все формулы, чтобы избежать циклов и условных переходов, упростить работу.
; a0 = X[9] + X[13] - X[11] - X[15]
; a1 = X[0] + X[4] - X[2] - X[6]
; a2 = X[0] + X[4] + X[2] + X[6]
; a3 = X[1] + X[5] + X[3] + X[7]
; a4 = X[0] - X[4] + X[10] - X[14]
; a5 = X[0] - X[4] - X[10] + X[14]
; a6 = X[1] - X[5] - X[3] + X[7]
; a7 = X[9] - X[13] + X[11] - X[15]
;
; x[0] = a2 + a3    
; x[1] = a5 + const*(a6 - a7)   
; x[2] = a1 - a0
; x[3] = a4 - const*(a6 + a7)
; x[4] = a2 - a3    
; x[5] = a5 - const*(a6 - a7)   
; x[6] = a1 + a0
; x[7] = a4 + const*(a6 + a7)
;

fninit
							; Будем класть значения на стек и считать a
fld real4 ptr[rdx]			; X[0]
fld real4 ptr[rdx + 4*2]	; X[2], X[0]
faddp						; X[0] + X[2]
fld real4 ptr[rdx + 4*4]	; X[4], X[0] + X[2]
faddp						; X[0] + X[2] + X[4]
fld real4 ptr[rdx + 4*6]	; X[6], X[0] + X[2] + X[4]
faddp						; a2
fld real4 ptr[rdx + 4]		; X[1], a2

fld real4 ptr[rdx + 4*3]	; X[3], X[1], a2
faddp						; X[1] + X[3], a2
fld real4 ptr[rdx + 4*5]	; X[5], X[1] + X[3], a2
faddp						; X[1] + X[3] + X[5], a2
fld real4 ptr[rdx + 4*7]	; X[7], X[1] + X[3] + X[5], a2
faddp						; a3, a2
fld st(1)					; a2, a3, a2
fsub st(0), st(1)			; x[4], a3, a2
fidiv toDiv					; перед тем, как класть значение в rcx, делим на 8
fistp word ptr[rcx + 2*4]	;  = x[4]

faddp						; x[0]
fidiv toDiv
fistp word ptr[rcx]			; = x[0]

fld real4 ptr[rdx + 4*9]	; X[9]
fld real4 ptr[rdx + 4*13]	; X[13], X[9]
faddp						; X[9] + X[13]
fld real4 ptr[rdx + 4*11]	; X[11], X[9] + X[13]
fsubp st(1), st(0)			; X[9] + X[13] - X[11]
fld real4 ptr[rdx + 4*15]	; X[15], X[9] + X[13] - X[11]
fsubp st(1), st(0)			; a0

fld real4 ptr[rdx]			; X[0], a0
fld real4 ptr[rdx + 4*4]	; X[4], X[0], a0
faddp						; X[0] + X[4], a0
fld real4 ptr[rdx + 4*2]	; X[2], X[0] + X[4], a0
fsubp st(1), st(0)			; X[0] + X[4] - X[2], a0
fld real4 ptr[rdx + 4*6]	; X[6], X[0] + X[4] - X[2], a0
fsubp st(1), st(0)			; a1, a0
fld st(0)					; a1, a1, a0
fsub st(0), st(2)			; x[2], a1, a0
fidiv toDiv
fistp word ptr[rcx + 2*2]	;  = x[2]
faddp						; x[6]
fidiv toDiv
fistp word ptr[rcx + 2*6]	;  = x[6]

fld real4 ptr[rdx]			; X[0]
fld real4 ptr[rdx + 4*4]	; X[4], X[0]
fsubp st(1), st(0)			; X[0] - X[4]
fld real4 ptr[rdx + 4*10]	; X[10], X[0] - X[4]
fsubp st(1), st(0)			; X[0] - X[4] - X[10]
fld real4 ptr[rdx + 4*14]	; X[14], X[0] - X[4] - X[10] 
faddp						; a5

fld real4 ptr[rdx + 4]		; X[1], a5
fld real4 ptr[rdx + 4*5]	; X[5], X[1], a5
fsubp st(1), st(0)			; X[1] - X[5], a5
fld real4 ptr[rdx + 4*7]	; X[7], X[1]- X[5], a5 
faddp						; X[1]- X[5] + X[7], a5
fld real4 ptr[rdx + 4*3]	; X[3], X[1] - X[5] + X[7], a5
fsubp st(1), st(0)			; a6, a5

fld real4 ptr[rdx + 4*9]	; X[9], a6, a5
fld real4 ptr[rdx + 4*13]	; X[13], X[9], a6, a5
fsubp st(1), st(0)			; X[9] - X[13], a6, a5
fld real4 ptr[rdx + 4*11]	; X[11], X[9] - X[13], a6, a5
faddp						; X[9] - X[13] + X[11], a6, a5
fld real4 ptr[rdx + 4*15]	; X[15], X[9] - X[13] + X[11], a6, a5
fsubp st(1), st(0)			; a7, a6, a5

fld st(1)					; a6, a7, a6, a5
fadd st(0), st(1)			; a6 + a7, a7, a6, a5
fxch st(1)					; a7, a6 + a7, a6, a5
fsubp st(2), st(0)			; a6 + a7, a6 - a7, a5

fld const					; загружаем const на стек
fmul st(2), st(0)
fmulp						; const*(a6 + a7), const*(a6 - a7), a5

fld st(2)
fadd st(0), st(2)			; x[1], const*(a6 + a7), const*(a6 - a7), a5
fidiv toDiv
fistp word ptr[rcx + 2*1]	; = x[1] 
fld st(2)
fsub st(0), st(2)			; x[5], const*(a6 + a7), const*(a6 - a7), a5
fidiv toDiv
fistp word ptr[rcx + 2*5]	; = x[5]


fld real4 ptr[rdx]			; X[0], const*(a6 + a7), const*(a6 - a7), a5
fld real4 ptr[rdx + 4*4]	; X[4], X[0], const*(a6 + a7), const*(a6 - a7), a5
fsubp st(1), st(0)			; X[0] - X[4], const*(a6 + a7), const*(a6 - a7), a5
fld real4 ptr[rdx + 4*10]	; X[10], X[0] - X[4], const*(a6 + a7), const*(a6 - a7), a5
faddp						; X[0] - X[4] + X[10], const*(a6 + a7), const*(a6 - a7), a5
fld real4 ptr[rdx + 4*14]	; X[14], X[0] - X[4] + X[10], const*(a6 + a7), const*(a6 - a7), a5
fsubp st(1), st(0)			; a4, const*(a6 + a7), const*(a6 - a7), a5

fld st(0)					; a4, a4, const*(a6 + a7), const*(a6 - a7), a5
fsub st(0), st(2)			; x[3], a4, const*(a6 + a7), const*(a6 - a7), a5
fidiv toDiv
fistp word ptr[rcx + 2*3]	; = x[3]
fadd st(0), st(1)			; x[7], const*(a6 + a7), const*(a6 - a7), a5
fidiv toDiv
fistp word ptr[rcx + 2*7]	; = x[7]
							
ffree st(0)					; очистим стек
ffree st(1)
ffree st(2)
ffree st(3)
ffree st(4)
ffree st(5)
ffree st(6)
ffree st(7)

	ret
RecoverSignal ENDP
END

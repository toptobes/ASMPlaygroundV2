extern _CRT_INIT:proc
extern printf:proc

.data
fizz_buzz_str	db ">> %s%s", 10, 0
number_str		db ">> %d", 10, 0
fizz			db "Fizz", 0
buzz			db "Buzz", 0
empty_str		db 0

.code
fizzbuzz proc
	call	_CRT_INIT		; Initialize C Runtime

	mov		r14, 1			; Set loop counter to 1
	lea		r15, empty_str	; Set r15 to the empty string

	FizzBuzzLoop:
		; Check for Fizz
		mov		rax, r14
		mov		r10, 3
		div		r10b

		lea		rdx, fizz	; Assume r14 % 3 == 0
		test	ah, ah		; Fact check time
		cmovnz	rdx, r15	; Welp, if it isn't, set it to an empty string

		; Check for Buzz
		mov		rax, r14
		mov		r10, 5
		div		r10b

		lea		r8, buzz	; Assume r14 % 5 == 0
		test	ah, ah		; Fact check time
		cmovnz	r8, r15		; Welp, if it isn't, set it to an empty string

		; Check if the number is Fizz/Buzz
		push	rcx			; I don't know why I'm pushing rcx, but the code breaks without it...
		lea		rcx, fizz_buzz_str
		cmp		rdx, r8		; If they're equal, it must mean they're both empty_str
		jne		IsFizzBuzzSoShouldContinue	

		; Change it to a number string if it's not Fizz/Buzz
		lea		rcx, number_str
		mov		rdx, r14

		IsFizzBuzzSoShouldContinue:

		; Print Fizz/Buzz/Number
		push	rbp
		sub		rsp, 32
		call	printf
		add		rsp, 32
        pop     rbp

		; Loop end + check condition
		pop		rcx
		inc		r14
		cmp		r14, 100
		jle		FizzBuzzLoop

	; Return with exit code 0
	xor		rax, rax
	ret
fizzbuzz endp
end
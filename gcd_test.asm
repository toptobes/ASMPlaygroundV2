extern gcd:proc
extern printf:proc

.data
number_str	db	"%d", 0

.code
gcd_test proc
	; Assign parameters for GCD
	mov		rcx, 56 * 57
	mov		rdx, 78 * 57

	; GCD
	call	        gcd

	; Assign parameters for printing
	lea		rcx, number_str
	mov		rdx, rax

	; Printf
	push	        rbp
	sub		rsp, 32
	call	        printf
	add		rsp, 32
    	pop             rbp

	; Return with exit code 0
	xor		rax, rax
	ret
gcd_test endp
end

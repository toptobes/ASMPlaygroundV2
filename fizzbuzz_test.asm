extern fizzbuzz:proc
extern printf:proc

.code
fizzbuzz_test proc
	push	rbp
	call	fizzbuzz
	pop		rbp

	; Return with exit code 0
	xor		rax, rax
	ret
fizzbuzz_test endp
end
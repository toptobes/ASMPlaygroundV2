.code
gcd proc
	cmp		rcx, 0			; Check if rcx or rdx are <= 0
	jle		Error			; If either is, it jumps to Error
	cmp		rdx, 0			; ...which returns 0
	jle		Error			

	mov		rax, rcx		; Move rcx the rax so it is the dividend

	GCDLoop:				; Loops that runs until rax % rdx == 0
		mov		r8, rdx		; Save r8 to rdx as rdx will be overridden
		xor		rdx, rdx	; Zero out rdx
		div		r8		; Divide rax by r8 (aka rdx)
	
		mov		rax, r8		; The divisor will be dividend next interation

		cmp		rdx, 0		; If rax % rdx != 0...
		jnz		GCDLoop		; Continue the loop

	mov		rax, r8			; Set the return value to the GCD
	ret					; Return (this one is here for OCD purposes)

	Error:
		mov		rax, 0
		ret
gcd endp
end

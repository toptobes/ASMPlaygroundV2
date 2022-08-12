extern getchar:proc

;; Directions:
;;  - left -> 0
;;  - up -> 1
;;  - right -> 2
;;  - down -> 3

.data
up		db	3	; Rotate thrice
right	db	2	; Rotate twice
down	db	1	; Rotate once
left	db	0	; Don't rotate

quit	db	-2	; Code for quitting

.code
;; ----------------------------------------------------------------------------
;;	Utility macro for use with the following procedure; If the input key
;;	matches the given 'key', the given 'code' is returned
;; ----------------------------------------------------------------------------
IF_KEY_THEN macro key, code
	movzx	rcx, code	; Load the given code into rbx
	cmp		rbx, key	; Compare the input key and the given key; 
	cmove	rax, rcx	; If they're the same, move the key into rax
	je		Finished	; and jump to the Finish Point
endm

;; ----------------------------------------------------------------------------
;;	Returns the code that corresponds to a given input key
;;	
;;	Returns: Corresponding code, with '-1' if none match
;; ----------------------------------------------------------------------------
get_next_direction proc
	push	rbx

	sub		rsp, 32
	call	getchar			; Get user input
	add		rsp, 32

	mov		rbx, rax		; Store user input in rbx
	
	call	flush_input		; Flush the input stream

	IF_KEY_THEN		"w", up
	IF_KEY_THEN		"a", left
	IF_KEY_THEN		"s", down
	IF_KEY_THEN		"d", right

	IF_KEY_THEN		"h", left
	IF_KEY_THEN		"j", down
	IF_KEY_THEN		"k", up
	IF_KEY_THEN		"l", right

	IF_KEY_THEN		"q", quit

	mov		rax, -1			; Return -1 if none of the above match

	Finished:
		pop	rbx
		ret
get_next_direction endp

;; ----------------------------------------------------------------------------
;;	Flushes the input stream so multiple reads aren't taken from multi-char inputs
;; ----------------------------------------------------------------------------
flush_input	proc
	sub		rsp, 32

	ReadLoop:
		call	getchar		; Read in a char

		cmp		rax, 10		; If it's a newline, stop
		je		Flushed

		cmp		rax, -1		; If it's EOF, stop
		je		Flushed

		jmp	ReadLoop		; Repeat until one of the following conditions are met

	Flushed:
		add		rsp, 32
		ret
flush_input	endp
end
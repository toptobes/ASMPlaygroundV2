extern	printf:proc

.data
number_str		db " %4d ", 0
horizontal_ln	db " ------ ", 0
vertical_line	db "|", 0
new_line		db 10, 0

; Variables for each of the 2048 tile colors for the background w/ black text
blank_tile_color            db 27, "[38;2;0;0;0;48;2;207;195;184m", 0
two_tile_color				db 27, "[38;2;0;0;0;48;2;238;228;218m", 0
four_tile_color             db 27, "[38;2;0;0;0;48;2;237;224;200m", 0
eight_tile_color            db 27, "[38;2;0;0;0;48;2;242;177;121m", 0
sixteen_tile_color          db 27, "[38;2;0;0;0;48;2;245;149;99m", 0
thirtytwo_tile_color		db 27, "[38;2;0;0;0;48;2;246;124;95m", 0
sixtyfour_tile_color		db 27, "[38;2;0;0;0;48;2;246;94;59m", 0
onetwentyeight_tile_color   db 27, "[38;2;0;0;0;48;2;237;207;114m", 0
twofiftysix_tile_color		db 27, "[38;2;0;0;0;48;2;237;204;97m", 0
fiveonetwo_tile_color		db 27, "[38;2;0;0;0;48;2;237;200;80m", 0
tentwentyfour_tile_color    db 27, "[38;2;0;0;0;48;2;237;197;63m", 0
twofourtyeight_tile_color   db 27, "[38;2;0;0;0;48;2;237;194;46m", 0
undefined_tile_color		db 27, "[38;2;0;0;0;48;2;35;148;62m", 0
clear_color					db 27, "[0m", 0

.code
;; ----------------------------------------------------------------------------
;;	Utility macro to print stuff.
;; ----------------------------------------------------------------------------
PRINT macro string
	push	rcx		; Don't ask me why I have to push rcx... 
	lea		rcx, string
	sub		rsp, 32
	call	printf
	add		rsp, 32
	pop		rcx		; I have no clue, but it breaks w/out it
endm

;; ----------------------------------------------------------------------------
;;	Utility macro to print stuff with a color derived from a calculated index
;; ----------------------------------------------------------------------------
PRINTC macro string
	movzx	edx, word ptr [rsi + r14 * 2]
	mov		ecx, edx
	call	get_color
	PRINT	[rax]
	movzx	edx, word ptr [rsi + r14 * 2]
	PRINT	string
	PRINT	clear_color
endm

;; ----------------------------------------------------------------------------
;;	Prints the board in a pretty way
;; 
;;  Params: rcx -> board ptr
;; ----------------------------------------------------------------------------
print_board proc
	push	rbx
	push	rbp
	
	mov		rsi, rcx		; Set the board pointer to the RSI register

	xor		r15, r15		; Row loop counter
	RowIterations:
		xor		r14, r14	; Col loop counter
		ColIterations1:
			PRINTC	horizontal_ln

			inc		r14
			cmp		r14, 4
			jl		ColIterations1	; Go through this loop once per col
		PRINT	new_line

		xor		r14, r14	; Col loop counter
		ColIterations2:
			PRINTC	vertical_line
			PRINTC	number_str
			PRINTC	vertical_line

			inc		r14
			cmp		r14, 4
			jl		ColIterations2	; Go through this loop once per col
		PRINT	new_line

		xor		r14, r14	; Col loop counter
		ColIterations3:
			PRINTC	horizontal_ln

			inc		r14
			cmp		r14, 4
			jl		ColIterations3	; Go through this loop once per col
		PRINT	new_line

		add		rsi, 8

		inc		r15
		cmp		r15, 4
		jl		RowIterations		; Go through this loop once per col

	pop		rbp
	pop		rbx
	ret	
print_board endp

;; ----------------------------------------------------------------------------
;;	Utility macro for use with the following procedure; If the tile number
;;	matches the given 'num', the given 'color' is returned
;; ----------------------------------------------------------------------------
.code
IF_NUM_THEN macro num, color
	lea		rbx, color	; Load the given color into rbx
	cmp		rcx, num	; Compare the tile number and the given number
	cmove	rax, rbx	; If they're the same, move the color into rax
	je		Finished	; and jump to the Finish Point
endm

;; ----------------------------------------------------------------------------
;;	Returns the color that corresponds to the given tile number
;;	
;;	Params: rcx -> tile number
;;	
;;	Returns: Corresponding color, with 'undefined_tile_color' if none match
;; ----------------------------------------------------------------------------
get_color proc
	push	rbx

	IF_NUM_THEN	0, blank_tile_color           		
	IF_NUM_THEN	2, two_tile_color						
	IF_NUM_THEN	4, four_tile_color            		
	IF_NUM_THEN	8, eight_tile_color           		
	IF_NUM_THEN	16, sixteen_tile_color         		
	IF_NUM_THEN	32, thirtytwo_tile_color				
	IF_NUM_THEN	64, sixtyfour_tile_color				
	IF_NUM_THEN	128, onetwentyeight_tile_color  		
	IF_NUM_THEN	256, twofiftysix_tile_color				
	IF_NUM_THEN	512, fiveonetwo_tile_color				
	IF_NUM_THEN	1024, tentwentyfour_tile_color   		
	IF_NUM_THEN	2048, twofourtyeight_tile_color  		
	lea			rax, undefined_tile_color				

	Finished:
		pop	rbx
		ret
get_color endp
end
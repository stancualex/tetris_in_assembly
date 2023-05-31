.586
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern memcpy: proc
extern fopen: proc
extern fclose: proc
extern fread: proc
extern fwrite: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; sectiunile programului, date, respectiv cod
.data
; aici declaram date
window_title db "Tetris | Stancu Alex-Daniel", 0

file_name db "score.dat", 0
mode_read db "rb", 0
mode_write db "wb", 0

area_width equ 1280
area_height equ 720
area dd 0

board_width equ 10
board_height equ 20

col_inc dd 0
row_inc dd 0

board dd board_width * board_height dup(0)
board_buf dd board_width * board_height dup(0)
ghost_buf dd board_width * board_height dup(0)

shapes dd 0, 0, 0, 0 ; I
       dd 1, 1, 1, 1
       dd 0, 0, 0, 0
       dd 0, 0, 0, 0
       dd 2, 0, 0 ; J
       dd 2, 2, 2
       dd 0, 0, 0
       dd 0, 0, 0
       dd 0, 0, 0, 0
       dd 0, 0, 3 ; L
       dd 3, 3, 3
       dd 0, 0, 0
       dd 0, 0, 0
       dd 0, 0, 0, 0
       dd 4, 4 ; O
       dd 4, 4
       dd 0, 0, 0, 0
       dd 0, 0, 0, 0
       dd 0, 0, 0, 0
       dd 0, 5, 5 ; S
       dd 5, 5, 0
       dd 0, 0, 0
       dd 0, 0, 0
       dd 0, 0, 0, 0
       dd 6, 6, 0 ; Z
       dd 0, 6, 6
       dd 0, 0, 0
       dd 0, 0, 0
       dd 0, 0, 0, 0
       dd 0, 7, 0 ; T
       dd 7, 7, 7
       dd 0, 0, 0
       dd 0, 0, 0
       dd 0, 0, 0, 0

sizes dd 4, 3, 3, 2, 3, 3, 3
starting_col dd board_width / 2 - 2
             dd board_width / 2 - 1
             dd board_width / 2 - 1
             dd board_width / 2 - 1
             dd board_width / 2 - 1
             dd board_width / 2 - 1
             dd board_width / 2 - 1
starting_row dd -1, 0, 0, 0, 0, 0, 0

curr_shape dd 16 dup(0)
buf_shape dd 16 dup(0)

curr_size dd 0
curr_col dd 0
curr_row dd 0

ghost_col dd 0
ghost_row dd 0

score dd 0
score_threshold equ 10
score_x equ board_x - area_width / 8
score_y equ area_height / 2

hi_score dd 0
hi_score_x equ score_x
hi_score_y equ area_height / 8

game_over dd 0
game_over_x equ board_x + cell_size * board_width + area_width / 8
game_over_y equ area_height / 2 - 20

line_offset dd 0
cell_size equ area_height / (board_height + 1)
board_x equ area_width / 2 - board_width * cell_size / 2
board_y equ area_height / 2 - board_height * cell_size / 2

square_inc dd 0
temp dd 0

counter_ok dd 0 ; un fel de divizor de frecventa

arg1 equ 8
arg2 equ 12
arg3 equ 16
arg4 equ 20

white equ 0ffffffh
grey equ 323232h

cyan equ 56b6c2h
blue equ 61afefh
orange equ 0c49060h
yellow equ 0e5c07bh
green equ 98c379h
red equ 0e06c75h
purple equ 0c678ddh

dark_cyan equ 36585ch
dark_blue equ 3c576eh
dark_orange equ 5e4b3ah
dark_yellow equ 78694dh
dark_green equ 546647h
dark_red equ 6b4145h
dark_purple equ 62456bh

symbol_width equ 10
symbol_height equ 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

make_text proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters

draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], white ; foreground
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], grey ; background
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, draw_area, x, y
	push y
	push x
	push draw_area
	push symbol
	call make_text
	add esp, 16
endm

make_pixel macro x, y
    mov eax, y
    mov ebx, area_width
    mul ebx
    add eax, x
    shl eax, 2
    add eax, area
endm

horizontal_line macro x, y, len, color
    local line_loop
    make_pixel x, y
    mov ecx, len
line_loop:
    mov dword ptr [eax], color
    add eax, 4
    loop line_loop
endm

vertical_line macro x, y, len, color
    local line_loop
    make_pixel x, y
    mov ecx, len
line_loop:
    mov dword ptr [eax], color
    add eax, 4 * area_width
    loop line_loop
endm

draw_cell macro col, row, color
    local square_loop
    mov ebx, cell_size
    mov eax, row
    mul ebx
    add eax, board_y + 1
    mov square_inc, eax
    mov eax, col
    mul ebx
    add eax, board_x + 1
    mov temp, eax

    mov eax, row
    mov ebx, cell_size
    mul ebx
    add eax, board_y
    add eax, cell_size
    mov esi, eax
square_loop:
    horizontal_line temp, square_inc, cell_size - 1, color
    inc square_inc
    cmp square_inc, esi
    jl square_loop
endm

clear_buf macro buffer
    push board_width * board_height * 4
    push 0
    push offset buffer
    call memset
    add esp, 12
endm

; arg1: buffer pointer
; arg2: shape col
; arg3: shape row

set_buf proc
    push ebp
    mov ebp, esp
    sub esp, 12

    mov esi, [ebp + arg1]
    mov edi, 0
    mov row_inc, 0
set_rows:
    mov col_inc, 0
set_cols:
    cmp curr_shape[edi], 0
    je continue_loop
    mov eax, [ebp + arg3]
    add eax, row_inc
    mov ebx, board_width
    mul ebx
    add eax, [ebp + arg2]
    add eax, col_inc
    shl eax, 2
    mov ebx, curr_shape[edi]
    mov dword ptr [esi + eax], ebx
continue_loop:
    add edi, 4
    inc col_inc
    mov ebx, curr_size
    cmp col_inc, ebx
    jl set_cols
    inc row_inc
    mov ebx, curr_size
    cmp row_inc, ebx
    jl set_rows

    mov esp, ebp
    pop ebp
    ret 12
set_buf endp

set_buf_macro macro buffer, col, row
    push row
    push col
    push offset buffer
    call set_buf
endm

draw_board proc
    push ebp
    mov ebp, esp

    cmp game_over, 1
    je proc_end

    clear_buf board_buf
    set_buf_macro board_buf, curr_col, curr_row

    call new_ghost
    clear_buf ghost_buf
    set_buf_macro ghost_buf, ghost_col, ghost_row

    mov edi, 0
    mov row_inc, 0
draw_board_rows:
    mov col_inc, 0
draw_board_cols:
    cmp board_buf[edi], 1
    je draw_cyan
    cmp ghost_buf[edi], 1
    je draw_dark_cyan
    cmp board[edi], 1
    je draw_cyan
    cmp board_buf[edi], 2
    je draw_blue
    cmp ghost_buf[edi], 2
    je draw_dark_blue
    cmp board[edi], 2
    je draw_blue
    cmp board_buf[edi], 3
    je draw_orange
    cmp ghost_buf[edi], 3
    je draw_dark_orange
    cmp board[edi], 3
    je draw_orange
    cmp board_buf[edi], 4
    je draw_yellow
    cmp ghost_buf[edi], 4
    je draw_dark_yellow
    cmp board[edi], 4
    je draw_yellow
    cmp board_buf[edi], 5
    je draw_green
    cmp ghost_buf[edi], 5
    je draw_dark_green
    cmp board[edi], 5
    je draw_green
    cmp board_buf[edi], 6
    je draw_red
    cmp ghost_buf[edi], 6
    je draw_dark_red
    cmp board[edi], 6
    je draw_red
    cmp board_buf[edi], 7
    je draw_purple
    cmp ghost_buf[edi], 7
    je draw_dark_purple
    cmp board[edi], 7
    je draw_purple
    jmp draw_grey
draw_cyan:
    draw_cell col_inc, row_inc, cyan
    jmp continue_loop
draw_dark_cyan:
    draw_cell col_inc, row_inc, dark_cyan
    jmp continue_loop
draw_blue:
    draw_cell col_inc, row_inc, blue
    jmp continue_loop
draw_dark_blue:
    draw_cell col_inc, row_inc, dark_blue
    jmp continue_loop
draw_orange:
    draw_cell col_inc, row_inc, orange
    jmp continue_loop
draw_dark_orange:
    draw_cell col_inc, row_inc, dark_orange
    jmp continue_loop
draw_yellow:
    draw_cell col_inc, row_inc, yellow
    jmp continue_loop
draw_dark_yellow:
    draw_cell col_inc, row_inc, dark_yellow
    jmp continue_loop
draw_green:
    draw_cell col_inc, row_inc, green
    jmp continue_loop
draw_dark_green:
    draw_cell col_inc, row_inc, dark_green
    jmp continue_loop
draw_red:
    draw_cell col_inc, row_inc, red
    jmp continue_loop
draw_dark_red:
    draw_cell col_inc, row_inc, dark_red
    jmp continue_loop
draw_purple:
    draw_cell col_inc, row_inc, purple
    jmp continue_loop
draw_dark_purple:
    draw_cell col_inc, row_inc, dark_purple
    jmp continue_loop
draw_grey:
    draw_cell col_inc, row_inc, grey
continue_loop:
    add edi, 4
    inc col_inc
    cmp col_inc, board_width
    jl draw_board_cols
    inc row_inc
    cmp row_inc, board_height
    jl draw_board_rows

proc_end:
    mov esp, ebp
    pop ebp
    ret
draw_board endp

; arg1: col
; arg2: row

is_valid_pos proc
    push ebp
    mov ebp, esp
    sub esp, 8

    mov edi, 0
    mov row_inc, 0
loop_rows:
    mov col_inc, 0
loop_cols:
    cmp curr_shape[edi], 0
    je continue_loop
    mov eax, [ebp + arg1]
    add eax, col_inc
    cmp eax, 0
    jl is_false
    cmp eax, board_width
    jge is_false
    mov eax, [ebp + arg2]
    add eax, row_inc
    cmp eax, board_height
    jge is_false
    mov eax, [ebp + arg2]
    add eax, row_inc
    mov ebx, board_width
    mul ebx
    add eax, [ebp + arg1]
    add eax, col_inc
    shl eax, 2
    cmp board[eax], 0
    jne is_false
continue_loop:
    add edi, 4
    inc col_inc
    mov ebx, curr_size
    cmp col_inc, ebx
    jl loop_cols
    inc row_inc
    mov ebx, curr_size
    cmp row_inc, ebx
    jl loop_rows

    mov eax, 1
    jmp proc_end

is_false:
    mov eax, 0

proc_end:
    mov esp, ebp
    pop ebp
    ret 8
is_valid_pos endp

check_pos macro col, row
    push row
    push col
    call is_valid_pos
endm

copy_mem macro dest, src, amount
    push amount
    push src
    push offset dest
    call memcpy
    add esp, 12
endm

new_shape proc
    push ebp
    mov ebp, esp

    rdtsc
    xor edx, edx
    mov ebx, 7
    div ebx
    mov edi, edx
    shl edi, 6

    lea esi, shapes
    add esi, edi

    shr edi, 4
    copy_mem curr_shape, esi, 64
    mov ebx, starting_col[edi]
    mov curr_col, ebx
    mov ebx, starting_row[edi]
    mov curr_row, ebx
    mov ebx, sizes[edi]
    mov curr_size, ebx
    check_pos curr_col, curr_row
    cmp eax, 1
    je proc_end
    inc curr_row
    mov game_over, 1

proc_end:
    mov esp, ebp
    pop ebp
    ret
new_shape endp

new_ghost proc
    push ebp
    mov ebp, esp

    mov ebx, curr_col
    mov ghost_col, ebx
    mov ebx, curr_row
    mov ghost_row, ebx

move_down:
    check_pos ghost_col, ghost_row
    cmp eax, 0
    je proc_end
    inc ghost_row
    jmp move_down

proc_end:
    dec ghost_row

    mov esp, ebp
    pop ebp
    ret
new_ghost endp

update_board proc
    push ebp
    mov ebp, esp

    mov row_inc, 0
    mov edi, 0
loop_rows:
    mov col_inc, 0
loop_cols:
    cmp curr_shape[edi], 0
    je continue_loop
    mov eax, curr_row
    add eax, row_inc
    mov ebx, board_width
    mul ebx
    add eax, curr_col
    add eax, col_inc
    shl eax, 2
    mov ebx, curr_shape[edi]
    mov board[eax], ebx
continue_loop:
    add edi, 4
    inc col_inc
    mov eax, curr_size
    cmp col_inc, eax
    jl loop_cols
    inc row_inc
    cmp row_inc, eax
    jl loop_rows

    mov esp, ebp
    pop ebp
    ret 
update_board endp

; arg1: row

is_row_full proc
    push ebp
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + arg1]
    mov ebx, board_width
    mul ebx
    shl eax, 2
    mov col_inc, 0
loop_row:
    cmp board[eax], 0
    je is_false
    add eax, 4
    inc col_inc
    cmp col_inc, board_width
    jl loop_row

    mov eax, 1
    jmp proc_end

is_false:
    mov eax, 0

proc_end:
    mov esp, ebp
    pop ebp
    ret 4
is_row_full endp

update_rows proc
    push ebp
    mov ebp, esp

    mov row_inc, 0
loop_rows:
    push row_inc
    call is_row_full
    cmp eax, 0
    je continue_loop
    inc score
    mov ecx, row_inc
rows_cleanup:
    mov col_inc, 0
cols_cleanup:
    mov eax, ecx
    mov ebx, board_width
    mul ebx
    add eax, col_inc
    shl eax, 2
    push eax
    mov eax, ecx
    dec eax
    mov ebx, board_width
    mul ebx
    add eax, col_inc
    shl eax, 2
    pop ebx
    mov edi, board[eax]
    mov board[ebx], edi
    inc col_inc
    cmp col_inc, board_width
    jl cols_cleanup
    dec ecx
    cmp ecx, 0
    jge rows_cleanup
    mov col_inc, 0
    mov edi, 0
loop_cols:
    mov board[edi], 0
    inc col_inc
    add edi, 4
    cmp col_inc, board_width
    jl loop_cols
continue_loop:
    inc row_inc
    cmp row_inc, board_height
    jl loop_rows

    mov esp, ebp
    pop ebp
    ret 
update_rows endp

rotate_right proc
    push ebp
    mov ebp, esp

    lea edi, curr_shape
    copy_mem buf_shape, edi, 64

    mov row_inc, 0
loop_rows:
    mov col_inc, 0
    mov ecx, curr_size
    dec ecx
loop_cols:
    mov eax, row_inc
    mov ebx, curr_size
    mul ebx
    add eax, col_inc
    shl eax, 2
    push eax
    mov eax, ecx
    mov ebx, curr_size
    mul ebx
    add eax, row_inc
    shl eax, 2
    pop ebx
    mov edi, buf_shape[eax]
    mov curr_shape[ebx], edi
    inc col_inc
    dec ecx
    mov ebx, curr_size
    cmp col_inc, ebx
    jl loop_cols
    inc row_inc
    mov ebx, curr_size
    cmp row_inc, ebx
    jl loop_rows

    mov esp, ebp
    pop ebp
    ret
rotate_right endp

rotate_left proc
    push ebp
    mov ebp, esp

    lea edi, curr_shape
    copy_mem buf_shape, edi, 64

    mov row_inc, 0
    mov ecx, curr_size
    dec ecx
loop_rows:
    mov col_inc, 0
loop_cols:
    mov eax, row_inc
    mov ebx, curr_size
    mul ebx
    add eax, col_inc
    shl eax, 2
    push eax
    mov eax, col_inc
    mov ebx, curr_size
    mul ebx
    add eax, ecx
    shl eax, 2
    pop ebx
    mov edi, buf_shape[eax]
    mov curr_shape[ebx], edi
    inc col_inc
    mov ebx, curr_size
    cmp col_inc, ebx
    jl loop_cols
    inc row_inc
    dec ecx
    mov ebx, curr_size
    cmp row_inc, ebx
    jl loop_rows

    mov esp, ebp
    pop ebp
    ret
rotate_left endp

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click, 3 - s-a apasat o tasta)
; arg2 - x (in cazul apasarii unei taste, x contine codul ascii al tastei care a fost apasata)
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha

	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
    cmp eax, 3
    jz evt_keyboard
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	; mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 50 ; culoarea gri inchis
	push area
	call memset
	add esp, 12

    mov line_offset, board_y
horizontal_line_loop:
    horizontal_line board_x, line_offset, board_width * cell_size, white
    add line_offset, cell_size
    cmp line_offset, board_y + board_height * cell_size
    jle horizontal_line_loop

    mov line_offset, board_x
vertical_line_loop:
    vertical_line line_offset, board_y, board_height * cell_size, white
    add line_offset, cell_size
    cmp line_offset, board_x + board_width * cell_size
    jle vertical_line_loop

game_on:
    mov game_over, 0
    mov score, 0

    push offset mode_read
    push offset file_name
    call fopen
    add esp, 8

    cmp eax, 0
    je skip_read

    push eax

    push eax
    push 1
    push 4
    push offset hi_score
    call fread
    add esp, 16

    pop eax

    push eax
    call fclose
    add esp, 4

skip_read:

	make_text_macro ' ', area, game_over_x - 40, game_over_y
	make_text_macro ' ', area, game_over_x - 30, game_over_y
	make_text_macro ' ', area, game_over_x - 20, game_over_y
	make_text_macro ' ', area, game_over_x - 10, game_over_y
	make_text_macro ' ', area, game_over_x, game_over_y
	make_text_macro ' ', area, game_over_x + 10, game_over_y
	make_text_macro ' ', area, game_over_x + 20, game_over_y
	make_text_macro ' ', area, game_over_x + 30, game_over_y
	make_text_macro ' ', area, game_over_x + 40, game_over_y

    clear_buf board
    call new_shape
    call draw_board

	jmp afisare_scor

et_game_over:
	make_text_macro 'G', area, game_over_x - 40, game_over_y
	make_text_macro 'A', area, game_over_x - 30, game_over_y
	make_text_macro 'M', area, game_over_x - 20, game_over_y
	make_text_macro 'E', area, game_over_x - 10, game_over_y
	make_text_macro ' ', area, game_over_x, game_over_y
	make_text_macro 'O', area, game_over_x + 10, game_over_y
	make_text_macro 'V', area, game_over_x + 20, game_over_y
	make_text_macro 'E', area, game_over_x + 30, game_over_y
	make_text_macro 'R', area, game_over_x + 40, game_over_y

    mov ecx, hi_score
    cmp score, ecx
    jle no_hi_score

    push offset mode_write
    push offset file_name
    call fopen
    add esp, 8

    cmp eax, 0
    je no_hi_score

    mov ebx, score
    mov hi_score, ebx

    push eax

    push eax
    push 1
    push 4
    push offset score
    call fwrite
    add esp, 16

    pop eax

    push eax
    call fclose
    add esp, 4

no_hi_score:
    jmp afisare_scor

evt_click:
    jmp afisare_scor

evt_keyboard:
    mov eax, [ebp + arg2]

    cmp game_over, 1
    je restart_game

    cmp eax, 'A'
    je a_press
    cmp eax, 'D'
    je d_press
    cmp eax, 'S'
    je s_press
    cmp eax, 'Q'
    je q_press
    cmp eax, 'E'
    je e_press
    cmp eax, 'W'
    je w_press

    jmp key_post

restart_game:
    cmp eax, 'R'
    je game_on

    jmp key_post
    
a_press:
    dec curr_col
    check_pos curr_col, curr_row
    cmp eax, 1
    je key_post
    inc curr_col
    jmp key_post
d_press:
    inc curr_col
    check_pos curr_col, curr_row
    cmp eax, 1
    je key_post
    dec curr_col
    jmp key_post
s_press:
    inc curr_row
    check_pos curr_col, curr_row
    cmp eax, 1
    je key_post
    dec curr_row
    call update_board
    call update_rows
    call new_shape
    jmp key_post
q_press:
    call rotate_left
    check_pos curr_col, curr_row
    cmp eax, 1
    je key_post
    call rotate_right
    jmp key_post
e_press:
    call rotate_right
    check_pos curr_col, curr_row
    cmp eax, 1
    je key_post
    call rotate_left
    jmp key_post
w_press:
    check_pos curr_col, curr_row
    cmp eax, 0
    je set_piece
    inc curr_row
    jmp w_press
set_piece:
    dec curr_row
    call update_board
    call update_rows
    call new_shape
    jmp key_post

key_post:
    call draw_board
    jmp afisare_scor

evt_timer:
    cmp game_over, 1
    je et_game_over
    cmp score, 3 * score_threshold
    jge level_3
    cmp score, 2 * score_threshold
    jge level_2
    cmp score, score_threshold
    jge level_1
    jmp level_0
level_3:
    inc counter_ok
    cmp counter_ok, 2
    jge timer_ok
    jmp afisare_scor
level_2:
    inc counter_ok
    cmp counter_ok, 3
    jge timer_ok
    jmp afisare_scor
level_1:
    inc counter_ok
    cmp counter_ok, 4
    jge timer_ok
    jmp afisare_scor
level_0:
    inc counter_ok
    cmp counter_ok, 5
    jge timer_ok
    jmp afisare_scor

timer_ok:
    mov counter_ok, 0
    jmp s_press

afisare_scor:
	; afisam valoarea scorului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, score
	; cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, score_x + 10, score_y
	; cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, score_x, score_y
	; cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, score_x - 10, score_y

	make_text_macro 'S', area, score_x - 20, score_y - 20
	make_text_macro 'C', area, score_x - 10, score_y - 20
	make_text_macro 'O', area, score_x, score_y - 20
	make_text_macro 'R', area, score_x + 10, score_y - 20
	make_text_macro 'E', area, score_x + 20, score_y - 20

	; afisam valoarea high score-ului (sute, zeci si unitati)
	mov ebx, 10
	mov eax, hi_score
	; cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, hi_score_x + 10, hi_score_y
	; cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, hi_score_x, hi_score_y
	; cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, hi_score_x - 10, hi_score_y

	make_text_macro 'H', area, hi_score_x - 30, hi_score_y - 20
	make_text_macro 'I', area, hi_score_x - 20, hi_score_y - 20
	make_text_macro ' ', area, hi_score_x - 10, hi_score_y - 20
	make_text_macro 'S', area, hi_score_x, hi_score_y - 20
	make_text_macro 'C', area, hi_score_x + 10, hi_score_y - 20
	make_text_macro 'O', area, hi_score_x + 20, hi_score_y - 20
	make_text_macro 'R', area, hi_score_x + 30, hi_score_y - 20
	make_text_macro 'E', area, hi_score_x + 40, hi_score_y - 20

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	; alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	; apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);

	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20

	;terminarea programului
	push 0
	call exit
end start

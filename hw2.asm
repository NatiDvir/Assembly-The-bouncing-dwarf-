TITLE      (.asm)
; Natanel Dvir , id: 316049097		
; Avi Digmi , id: 313323420
INCLUDE Irvine32.inc
INCLUDE hw2_data.inc

.data
ByteSize = 8
E = 69
S = 83

Names byte "Avi Digmi 313323420, Natanel Dvir 316049097",0
output1 byte "moveseries ",0
output2 byte "score ",0

BOARDSIZE = lengthof board
Dsize = boardsize -1
sboard byte boardsize dup(?) ; Fixed board.
movessize = 0
moveseries byte Dsize dup(1) 
helper byte 0
score dword 0

.code
main PROC
mov edx, offset Names
call writestring
call crlf
call fixboard
mov eax,0
lea esi,sboard
push esi
mov eax,BOARDSIZE
push eax
call checkboard
cmp eax,1
je failed
mov eax,0
lea esi,sboard
push esi
mov eax,BOARDSIZE
push eax
mov eax,0 
mov al,nomoves
push eax
call findshortseries
cmp eax,1
je failed
mov eax,0
lea esi,sboard
push esi
mov eax,DSIZE
push eax
lea esi,moveseries
push esi 
call writescore
mov edx, offset output1
call writestring
call printmoves	
mov edx, offset output2
call writestring
call writedec

jmp NOICE

failed:
mov eax, -1
mov edx, offset output1
call writestring
call writeint
call crlf
mov edx, offset output2
call writestring
call writeint

NOICE:
exit
main ENDP


; EX 2 FUNCTIONS ! :

;this function summarizes the score for the series of moves
;the arguments passed in the stack are the board, board size and moves arry
writescore PROC uses ebx ecx edi edx esi 
movesptr = 28
sizeptr = movesptr + 4
boardptr = sizeptr + 4
push ebp
mov ebp, esp
mov ecx,0
mov ebx,0 ;Score 
mov edx,0 ;Distance
mov edi, [ebp+movesptr] ; Moves array 
mov esi, [ebp+boardptr] ; board
mov cl , helper ; moves array size

loop1:
dec ecx
mov eax,0
mov al,[edi] ; get move (1-6)
add esi,eax ; move the player
add dl,[edi] ; adding distance of move
cmp dl,[ebp+sizeptr] ; Check if we passed board borders
JBE OK ; if not check the move

OK:
mov al,[esi] ; get current number value
cmp al,E ; if elavate
JE Elavate 

chkslide:
cmp al,S ;if slide
JE Slide
JMP legalmove ; else - regular move

;______________________________ELAVATE_____START____________________________________
;current position + ((numcols*2-1) - (distance%numcols * 2)) = position after elavate
Elavate:
push ebx
push ecx
push ebp
mov ebp,esp
mov ebx,0
mov eax,0
movzx ebx,numcols
rol ebx,1
dec ebx ; ebx = numcols*2-1
mov ecx,0
mov eax, edx ; eax = distance
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah,1 ; ah = distance%numcols * 2
sub bl,ah ; ((numcols*2-1) - (distance%numcols * 2))
add edx, ebx ; add to distance
mov eax, ebx ; save the distance to advance esi if we need

mov esp,ebp
pop ebp
pop ecx
pop ebx
;______________________________ELAVATE_____END____________________________________
add esi, eax ; move player pointer in board
mov al, [esi] 
cmp al, E ; Check for another E
JE Elavate

add bl,al ; add value to score
inc edi ; Next Move

cmp ecx, 0
JA loop1

;_______________________________SLIDE__START______________________________________
; (current position) - (distance%numcols * 2 +1) 
Slide:
push ebx
push ecx 
push ebp 
mov ebp,esp
mov ecx,0
mov eax,edx
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah, 1 ; ah = distance%numcols * 2
inc ah ; ah = (distance%numcols * 2 +1) 
mov al,0
sub dl,ah

mov esp,ebp
pop ebp
pop ecx
pop ebx
;_______________________________SLIDE__END______________________________________
ror ax,8
sub esi, eax
mov eax,0
mov al , [esi] ;get new value

cmp al,S ; Check for another S
JE Slide

add bl,al ; add value to score
inc edi ; Next Move

cmp ecx, 0
JA loop1

legalmove:
add bl,al ; add value to score
inc edi  ; next move
cmp dl,[ebp+sizeptr] ;Check if won

cmp ecx, 0
JA loop1

Winner:
mov eax, ebx

EndGame:
mov esp,ebp
pop ebp
ret 12
writescore endp


;this function finds the shortest series of moves that wins for the given board
;the arguments passed in the stack are the board, board size, maximum number of moves, and moves arry
findshortseries PROC uses ebx ecx edi edx esi 
nomovesptr = 28
sizeptr = movesptr + 4
boardptr = sizeptr + 4
push ebp
mov ebp, esp
mov ebx,0 ;
mov edx,1 ;MOVES SIZE
mov ebx, [ebp+sizeptr] ; board size
dec ebx
mov esi, [ebp+boardptr] ; board pointer
mov ecx, [ebp+nomovesptr] ; pointer to moves array
lea edi, moveseries ; moves arr
mov eax,1
mov [edi], al

loop1:
getnextmove:
push esi ;board address
push ebx ;board size (DSIZE)
push edi ;moves address
mov helper,dl
call checksolved
cmp eax,-1
JNE FOUND
push edi ;moves address
push edx ;moves size
call nextmove
cmp eax,0 ;Check if its the last option
JE getnextmove
inc edx ;Check for bigger moves array
loop loop1

mov eax,1 ; If didnt found a solving series 
jmp finish

FOUND: ;Return 0 and add ';' to end of solving series.
push esi ;board address
push ebx ;board size (DSIZE)
push edi ;moves address
mov helper,dl
call checksolved

mov eax,0
mov ebx,0
mov bl,59
mov [edi+edx],bl

finish:
mov esp,ebp
pop ebp
ret 12
findshortseries ENDP


; ---checksolved STACK ---
; Board address : 4
; boardsize : 4
; Moves address : 4
; return address : 4
; 5 regs : 20
; ebp : 4
; this function checks whether the current series of moves leads to victory
checksolved PROC uses ebx ecx edi edx esi 
movesptr = 28
sizeptr = movesptr + 4
boardptr = sizeptr + 4
push ebp
mov ebp, esp
mov ecx,0
mov ebx,0 ;Score 
mov edx,0 ;Distance
mov edi, [ebp+movesptr] ; Moves array 
mov esi, [ebp+boardptr] ; board
mov cl , helper

loop1:
dec ecx
mov eax,0
mov al,[edi] ; get move (1-6)
add esi,eax ; move the player
add dl,[edi] ; adding distance of move
cmp dl,[ebp+sizeptr] ; Check if we passed board borders
JBE OK ; if not check the move
JMP Loss 

OK:
mov al,[esi] ; get current number value
cmp al,E ; if elavate
JE Elavate 

chkslide:
cmp al,S ;if slide
JE Slide
JMP legalmove ; else - regular move

;______________________________ELAVATE_____START____________________________________
;current position + ((numcols*2-1) - (distance%numcols * 2)) = position after elavate
Elavate:
push ebx
push ecx
push ebp
mov ebp,esp
mov ebx,0
mov eax,0
movzx ebx,numcols
rol ebx,1
dec ebx ; ebx = numcols*2-1
mov ecx,0
mov eax, edx ; eax = distance
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah,1 ; ah = distance%numcols * 2
sub bl,ah ; ((numcols*2-1) - (distance%numcols * 2))
add edx, ebx ; add to distance
mov eax, ebx ; save the distance to advance esi if we need

mov esp,ebp
pop ebp
pop ecx
pop ebx
;______________________________ELAVATE_____END____________________________________
; check for loss/win
cmp edx,boardsize 
JB MoveOn ;Didnt finish yet
cmp edx,boardsize
je Winner ;Got to last position
jmp Loss

MoveOn:
add esi, eax ; move player pointer in board
mov al, [esi] 
cmp al, E ; Check for another E
JE Elavate

add bl,al ; add value to score
inc edi ; Next Move

cmp ecx, 0
JA loop1

;_______________________________SLIDE__START______________________________________
; (current position) - (distance%numcols * 2 +1) 
Slide:
push ebx
push ecx 
push ebp 
mov ebp,esp
mov ecx,0
mov eax,edx
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah, 1 ; ah = distance%numcols * 2
inc ah ; ah = (distance%numcols * 2 +1) 
mov al,0
sub dl,ah
mov esp,ebp
pop ebp
pop ecx
pop ebx
;_______________________________SLIDE__END______________________________________
; check for loss/win
cmp edx, 0
JA next2 ; Didnt pass board's border
jmp Loss

next2:
ror ax,8
sub esi, eax
mov eax,0
mov al , [esi] ;get new value

cmp al,S ; Check for another S
JE Slide

add bl,al ; add value to score
inc edi ; Next Move

cmp ecx, 0
JA loop1

legalmove:
add bl,al ; add value to score
inc edi  ; next move
cmp dl,[ebp+sizeptr] ;Check if won
JE Winner

cmp ecx, 0
JA loop1

Loss:
mov eax,-1
jmp EndGame

Winner:
mov eax, ebx

EndGame:
mov esp,ebp
pop ebp
ret 12
checksolved ENDP


;this function get a array and update it to the next dictionary order array
;the function receives in the stack pointer to the array of moves and the size of the array
nextmove PROC uses ebx ecx edi edx esi ;
arrlen = 28
arr = arrlen + 4
push ebp 
mov ebp,esp
mov ecx,0
mov ecx,[ebp+arrlen]; array lenght
mov esi,[ebp+arr]; array
mov edx,1
mov ebx,0
mov eax,ecx
dec eax

loop1:
mov bl,byte ptr[esi+eax]
cmp bl,6
jl update
mov dl,1
mov byte ptr [esi+eax],dl
dec eax
loop loop1
mov eax,1
jmp endit

update:
inc ebx
mov [esi+eax],bl
mov eax,0

endit:
mov esp,ebp
pop ebp
ret 8
nextmove ENDP


;this function print moves array 
printmoves PROC uses ebx ecx eax edx esi ;
mov ecx,0
mov cl, helper
mov eax,0
lea esi, moveseries
mov ebx,0

loop1:
mov al,[esi+ebx]
call writedec
cmp ecx, 1
je lastnum
mov al,','
call writechar

lastnum:
inc ebx
loop loop1
call crlf

ret 0
printmoves ENDP


; ---checkboard STACK ---
; Board address : 4
; boardsize : 4
; return address : 4
; 5 regs : 20
; ebp : 4
;this function Checks if the board is proper
checkboard PROC uses  ebx ecx edi edx esi
sizeptr = 28
boardptr = sizeptr + 4
push ebp
mov ebp, esp
mov ecx,0
mov ecx, [ebp+sizeptr] ; board size
mov esi, [ebp+boardptr] ; board
mov eax,0
mov edx,0 ; distance

loop1:
cmp ecx,1
jne NotYet ; its not the last node
mov al,[esi]
cmp al,83
JE Error ; 'S' in last position (cant finish game)
;...................
NotYet:
mov al,[esi]
cmp al,69
jE IsE ; Check infinite loop for 'E'
cmp al,83
jE IsS ; Check infinite loops for 'S'
cmp al,40
jg Error ; Check if greater than 40
cmp al,1
jl Error ; Check if less than 1

jmp Continue 

IsE:
Elavate:
;current position + ((numcols*2-1) - (distance%numcols * 2)) = position after elavate
push ebx
push ecx
push ebp
mov ebp,esp
mov ebx,0
mov eax,0
movzx ebx,numcols
rol ebx,1
dec ebx ; ebx = numcols*2-1
mov ecx,0
mov eax, edx
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah,1 ; ah = distance%numcols * 2
sub bl,ah ; ((numcols*2-1) - (distance%numcols * 2))
add edx, ebx ; add to distance
mov eax, ebx ; save the distance to advance esi if we need
mov esp,ebp
pop ebp
pop ecx
pop ebx

; CHECK FOR INFINITE LOOP (IF WE REACH TO S)
mov edi,esi
add edi,eax
mov eax,0
mov al,[edi]
cmp al,83
je Error ; INFINITE LOOP
jmp Continue

IsS:
; (current position) - (distance%numcols * 2 +1) 
Slide:
push ebx
push ecx 
push ebp 
mov ebp,esp
mov ecx,0
mov eax,edx
movzx ecx,numcols
div cl ; ah = rest , rest = distance%numcols
sal ah, 1 ; ah = distance%numcols * 2
inc ah ; ah = (distance%numcols * 2 +1) 
mov al,0
mov edi,esi
mov ebx,0
mov bl,ah
sub edi,ebx
mov esp,ebp
pop ebp
pop ecx
pop ebx
mov eax,0
mov al,[edi]
cmp al,69
je Error ; infinte loop (Reached E)
jmp Continue

Continue:
inc esi
inc edx
; INSTEAD OF LOOP
dec ecx
cmp ecx, 0
JA loop1

mov eax,0
jmp ENDIT

Error:
mov eax,1

ENDIT:
mov esp,ebp
pop ebp
ret 8
checkboard ENDP


fixboard PROC uses eax ebx ecx edi edx esi ; esi - pointer to sboard current position in "sboard". edi - pointer to current position in the original board.
mov ebx,0
mov eax,0
mov edx,0
movzx ecx,numrows
dec ecx
lea edi,board
loop1: ;get pointer to start point, than use it to get the fixed array
push ecx
movzx ecx,numcols
loop2:
add edi,1
loop loop2
pop ecx
loop loop1
;in the end of this loops , edi contain the  start pointer of the board

mov eax,0
lea esi,sboard ; esi is a pointer to the fixed array
movzx ecx,numrows
loop3:
push ecx
mov ebx,0
cmp eax,0
movzx ecx,numcols;number of numbers in each row
jnz odd

loop4:;if row is even
mov bl,[edi]
mov [esi],bl 
inc edi
inc esi
loop loop4
inc eax
pop ecx
loop loop3

odd:;if row is odd

movzx ebx,numcols
inc ebx
sub edi,ebx
movzx ecx,numcols
mov ebx,0

loop5: ;goes from right number to left numbe
mov bl,[edi]
mov [esi],bl
dec edi
inc esi
loop loop5
mov eax,0 ;make sure next row is even
pop ecx
movzx ebx,numcols
dec ebx
sub edi,ebx ; make sure next row start from left number
loop loop3

mov ecx,boardsize
mov eax,0
lea esi,sboard

ret 0
fixboard ENDP

END main
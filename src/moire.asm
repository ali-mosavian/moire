                .model tiny, pascal
                .386
                option proc: private


;;::::::::
;COLOR_PATTERN   equ
TIME_STEP       equ     5


;;::::::::
vgaGetMode      proto   near
vgaSetMode      proto   near, :byte
drawMoire       proto   near time:dword, wdth:word, hght:word

;;::::::::
.const
F2              real4   2.0 
F3              real4   3.0 
F4              real4   4.0 
F1000           real4   1000.0


;;::::::::
.code
.startup
main            proc    near
                local   vdo_mode_no: byte

                ;; Get default video mode
                call    vgaGetMode
                mov     vdo_mode_no, al

                ;; Set mode 13h
                invoke  vgaSetMode, 13h

                xor     eax, eax
@loop:                
                xor     bx, bx
@@:
                invoke  drawMoire, eax, 320, 200
                add     eax, TIME_STEP
                inc     bx
                cmp     bx, 10
                jl      @B

                ;; Quit if key press detected
                push    eax             
                mov     ah, 01h
                int     16h
                pop     eax
                jnz     @exit 
                     
                jmp     @loop

@exit:
                invoke  vgaSetMode, vdo_mode_no
                
                ;; Exit to dos
                mov     ax, 04c00h
                int     21h                
main            endp    


;:::::
vgaGetMode      proc    near
                mov     ah, 0Fh
                int     10h
                ret
vgaGetMode      endp


;:::::
vgaSetMode      proc    near,
                        mode_no:byte

                xor     ax, ax
                mov     al, mode_no
                int     10h
                ret

vgaSetMode      endp


;:::::
; Inspired by
;  https://github.com/mrkite/demofx/blob/master/src/moire.ts
;
;
drawMoire       proc    near uses es di ax cx,
                        time:dword, wdth:word, hght:word

                local   tmp:real4,\ 
                        x:word, y:word,\
                        d1:word, d2:word,\
                        cx1:real4, cy1:real4,\
                        cx2:real4, cy2:real4
                
                ;; Set es:di -> VRAM
                push    0a000h
                pop     es
                xor     di, di

                ;; time = t/1000.0
                ;; cx1 = sin(time/2.0)*wdth/3.0 + wdth/2.0
                ;; cy1 = sin(time/4.0)*hght/3.0 + hght/2.0
                ;; cx2 = cos(time/3.0)*wdth/3.0 + wdth/2.0
                ;; cy2 = cos(time/1.0)*hght/3.0 + hght/2.0
                fild    wdth            ; w
                fld     st              ; w w
                fdiv    F3              ; w/3 w
                fxch    st(1)           ; w w/3
                fdiv    F2              ; w/2 w/3

                fild    hght            ; h w/2 w/3
                fld     st              ; h h w/2 w/3
                fdiv    F3              ; h/3 h w/2 w/3
                fxch    st(1)           ; h h/3 w/2 w/3
                fdiv    F2              ; h/2 h/3 w/2 w/3

                fild    time            ; time h/2 h/3 w/2 w/3
                fdiv    F1000           ; t h/2 h/3 w/2 w/3

                fld     st              ; t t h/2 h/3 w/2 w/3
                fdiv    F2              ; t/2 t h/2 h/3 w/2 w/3
                fsin                    ; sin(t/2) t h/2 h/3 w/2 w/3
                fmul    st(0), st(5)    ; sin(t/2)*w/3 t h/2 h/3 w/2 w/3
                fadd    st(0), st(4)    ; sin(t/2)*w/3+w/2 t h/2 h/3 w/2 w/3
                fstp    cx1             ; t h/2 h/3 w/2 w/3

                fld     st              ; t t h/2 h/3 w/2 w/3
                fdiv    F4              ; t/4 t h/2 h/3 w/2 w/3
                fsin                    ; sin(t/4) t h/2 h/3 w/2 w/3
                fmul    st(0), st(3)    ; sin(t/4)*h/3 t h/2 h/3 w/2 w/3
                fadd    st(0), st(2)    ; sin(t/4)*h/3+h/2 t h/2 h/3 w/2 w/3
                fstp    cy1             ; t h/2 h/3 w/2 w/3

                fld     st              ; t t h/2 h/3 w/2 w/3
                fdiv    F3              ; t/3 t h/2 h/3 w/2 w/3
                fcos                    ; cos(t/3) t h/2 h/3 w/2 w/3
                fmulp   st(5), st(0)    ; t h/2 h/3 w/2 cos(t/3)*w/3
                fxch    st(4)           ; cos(t/3)*w/3 h/2 h/3 w/2 t
                faddp   st(3), st(0)    ; h/2 h/3 cos(t/3)*w/3+w/2 t
                fxch    st(2)           ; cos(t/3)*w/3+w/2 h/2 h/3 t
                fstp    cx2             ; h/2 h/3 t

                fxch    st(2)           ; t h/3 h/2
                fcos                    ; cos(t) h/3 h/2
                fmulp   st(1), st(0)    ; cos(t)*h/3 h/2
                faddp   st(1), st(0)    ; cos(t)*h/3+h/2
                fstp    cy2             ;

                ;; for y = 0 to hght-1                          
                xor     ax, ax
                mov     y, ax
@yloop:
                ;; dy1 = (y-cy1)^2
                ;; dy2 = (y-cy2)^2
                fild    y               ; y
                fld     st              ; y y
                fsub    cy2             ; (y-cy2) y
                fmul    st(0), st(0)    ; dy2 y

                fxch                    ; y dy2
                fsub    cy1             ; (y-cy1) dy2
                fmul    st(0), st(0)    ; dy1 dy2

                ;; for x = 0 to wdth-1
                xor     bx, bx
                mov     x, bx
@xloop:                
                ;; dx1 = (x-cx1)^2
                ;; dx2 = (x-cx2)^2
                fild    x               ; x dy1 dy2
                fld     st              ; x x dy1 dy2 
                fsub    cx2             ; (x-cx2) x dy1 dy2 
                fmul    st(0), st(0)    ; dx2 x dy1 dy2 

                fxch                    ; x dx2 dy1 dy2 
                fsub    cx1             ; (x-cx1) dx2 dy1 dy2 
                fmul    st(0), st(0)    ; dx1 dx2 dy1 dy2 

                ;; d1 = sqr(dx1+dy1)
                ;; d2 = sqr(dx2+dy2)
                fadd    st(0), st(2)    ; dx1+dy1 dx2 dy1 dy2 
                fsqrt                   ; d1 dx2 dy1 dy2 
                fistp    d1             ; dx2 dy1 dy2 

                fadd    st(0), st(2)    ; dx2+dy2 dy1 dy2 
                fsqrt                   ; d2 dy1 dy2 
                fistp    d2             ; dy1 dy2 

                ;; col = (((d1 xor d2)/16) and 1) * 15
                mov     ax, d1 
                xor     ax, d2 
                
IFNDEF          COLOR_PATTERN
                shr     ax, 3
                and     ax, 1
                jz      @F
                mov     ax, 15
@@:
ELSE
                and     ax, 15
                add     ax, 50h
ENDIF                

                ;; video[x, y] = col
                mov     es:[di+bx], al

                ;; scanline done?
                inc     bx
                mov     x, bx
                cmp     bx, wdth
                jl      @xloop

                add     di, 320
                
                fstp    tmp ;real4 ptr ss:[sp]
                fstp    tmp ;real4 ptr ss:[sp]

                ;; All scanlines done yet?
                mov     ax, y
                inc     ax
                mov     y, ax
                cmp     ax, hght
                jl      @yloop
                
                ret
drawMoire       endp


END
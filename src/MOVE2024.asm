; MOVE.KCC
; fuer CAOS 4.7 bzw. 4.8 modifiziert
; und um Modulsuche erweitert

	org	03E00h  ; =15872

CAOS:       EQU 0F003h
IRMON:      EQU 0F018h
IRMOFF:     EQU 0F01Bh
UP_PADR:    EQU 034h

calc_addr:
	ld a,(PAR_YA)
	ld e,a	
	ld a,(PAR_YE)
	sub e	        ; Breite ermitteln
	inc a	
	ld (BREITE),a
	ld a,(PAR_XA)
	rla	            ; *2
	rla	            ; *4
	rla	            ; *8
	ld d,a	
	ld a,(PAR_XE)
	rla	            ; *2
	rla	            ; *4
	rla	            ; *8
	sub d	        ; Hoehe
	add a,008h
	ld (HOEHE),a
	ld b,a	
	ld hl,(P_ADRTAB)

    ; IRM-Adressen in Tabelle
    ; ablegen
    ; B = Schleifenanzahl
loop_col:
	push de	
	push hl	

	ex de,hl	
	call CAOS       ; in:  H = vert., L = horiz.
    DB UP_PADR      ; out: HL = pixeladdress
	ex de,hl	
	           
    pop hl	        ; Adresse in Tabelle
	ld (hl),e	    ; ablegen
	inc hl	
	ld (hl),d	
	inc hl	

	pop de	
	inc e	
	djnz loop_col

    ret


show_ani:

loop_again:
	ld hl,(MOD_TAB)
	ld c,(hl)       ; Anzahl Segmente	
	inc hl	

loop_segm:
	push bc	
	ld b,(hl)       ; Schacht	
	inc hl	

	ld c,080h
	ld a,(hl)	    ; Steuerbyte
	inc hl	

	out (c),a
	pop bc	

	ld b,(hl)       ; Sequenzen	
	inc hl	

	ld de, 04000h   ; Datenquelle
	ld (PIC_SRC),de ; initialisieren

loop_seq:
	push hl	
	push bc	
	call show_pic
	pop bc	
	pop hl	

	ret c           ; carry -> Ende
	djnz loop_seq

	dec c	
	jr nz,loop_segm

	ld a,(hl)	
	or a	        ; Wiederholung?
	jr nz,loop_again
    ret


save_pic:
	ld hl,(P_ADRTAB)
	ld a,(BREITE)
	ld b,a	        ; B = Breite
	ld a,(HOEHE)
	ld c,a	        ; C = Hoehe

copy_back:
	ld e,(hl)	
	inc hl	
	ld d,(hl)	
	inc hl	        ; DE = Zieladresse
	
    push hl	
	ld hl,(PIC_SRC)
	
    ex de,hl	
	push bc	
	ld b,000h
	ldir
	pop bc	
	
    ex de,hl	
	ld (PIC_SRC),hl
	pop hl	
	
    djnz copy_back
    ret


show_pic:
	ld hl,(P_ADRTAB)
	ld a,(BREITE)
	ld b,a	        ; B = Breite
	ld a,(HOEHE)
	ld c,a	        ; C = Hoehe

loop_cpy:
	ld e,(hl)	
	inc hl	        ; Quelle
	ld d,(hl)	    ; aus Tabelle
	inc hl          ; in DE	

	push hl	
	ld hl,(PIC_SRC)

	push bc	
	ld b,000h       ; nur Hoehe
	ldir            ; umkopieren
	pop bc

	ld (PIC_SRC),hl ; HL zwischnspeichern
	pop hl	
	
    djnz loop_cpy
	
    ld hl,PAR_WA    ; Wartezeit
	ld b,(hl)	    ; lo
sloop1:
	inc hl	
	ld c,(hl)	    ; hi
	dec hl	

sloop2:
	bit 0,(ix+008h) ; Tastencode bereit?
	jr z,show_next  ; nein -> weiter

	ld a,(001fdh)   ; ?? = IX+13 -> Tastaturcode
	res 0,(ix+008h) ; Taste quittieren
	cp 003h         ; Break?
	scf	
	ret z	        ; return, wenn Break

	sub 008h        ; Cursor links?
	call check_key

	inc hl	
	dec a	        ; Cursor rechts?
	call check_key
	dec hl	

show_next:
	dec c           ; wait_hi	
	jr nz,sloop2
	djnz sloop1
	or a	        ; carry loeschen
	ret	

    ; veraendert (HL)
    ; schneller <-> langsamer?
check_key:
	jr nz,check3
check1:
	inc (hl)	
	ret nz	
check2:
	dec (hl)	
	jr z,check1
check3:
	dec a	
	jr z,check2
	ret	


    ; Variablen
HOEHE:
    DB 80
BREITE:
    DB 10
PIC_SRC:            ; Quelldresse im RAM
    DW 055E0h
P_ADRTAB:
    DW 03F60h       ; TAB-Anfang
MOD_TAB:
    DW PAR_AN       ; Modultabelle


    ; Parameter
	org	03EE0h
PAR_WA:             ; Wartezeit
    DW 0187Eh
PAR_XA:             ; Fenster XA
    DB 00Bh
PAR_XE:
    DB 014h         ; Fenster XE
PAR_YA: 
    DB 00Fh         ; Fenster YA
PAR_YE:
    DB 018h         ; Fenster YE

PAR_AN:
    DB 4            ; Anzahl 16k-Blöcke
    DB 12, 043h, 20 ; Schacht, Steuerbyte, Sequenzen
    DB 12, 003h, 20
    DB 12, 0C3h, 20 
    DB 12, 083h, 20 
    DB 1            ; 1 = nochmal, 0 = Ende


    ; Parameter für mod_get_struct
	org	    03EFFh
MOD_PARAM:
    DS 1            

    ; Strukturbyte einlesen
    ; in = Modulschacht, out = Strukturbyte
	org	    03F00h
CALL_3F00:
    push    af
    push    bc
    ld      a, (MOD_PARAM)  ; Modulschacht holen
    ld      b, a
    ld      c, 080h
    in      a, (c)          ; = in a, (bc)
    ld      (MOD_PARAM), a  ; Strukturbyte ablegen
    pop     bc
    pop     af
    ret

    ; weitere Einsprungpunkte
	org	    03F10h
CALL_3F10:
	call    IRMON
	call    calc_addr
	call    IRMOFF
	ret	

	org	    03F20h
CALL_3F20:
	call    IRMON
	call    save_pic
	call    IRMOFF
	ret	

	org	    03F30h
CALL_3F30:
	call    IRMON
	call    show_ani
	call    IRMOFF
	ret	

	end

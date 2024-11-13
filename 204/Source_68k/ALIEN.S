**********************************************************************
* DEMONSTRATION OVERSCAN
**********************************************************************

mfp	equ	40	                  ; Délai mpf à partir duquel on teste.

Démonstration
	bsr	CLS			                ; Effacement écran
	move.b	#mfp,mfp_Ada+3		  ; Lancement du test adaptatif
	bsr	Adapt
	bsr	Set_Up_Hardware
	stop	#$2300
	stop	#$2300
	move.l	#VBL,$70.w
.loop addq.w	#1,d6
	cmp.b	#$B9,$fffffc02.w
	bne.s	.loop
	move.w	#$2700,sr
	rts

Set_Up_Hardware			          ; Initialisation du hardware.
	clr.l	$fffffa06.w	          ; On interdit les intérruptions
	clr.l	$fffffa12.w	          ; mfp.
	move.l	#RTE,$70.w	        ; Reset Shifter
	stop	#$2300	
	stop	#$2300	
	clr.b	$ffff820a.w
	stop	#$2300	
	move.b	#2,$ffff820a.w
	move.w	#$2700,sr           ; Mise en Basse résolution et en
	clr.b	$ffff8260.w           ; 50 Hz
	move.b	#$2,$ffff820a.w
	lea	$fffffa00.w,a0          ; Initialisation mpf
	clr.l	$0A(a0)
	clr.b	$19(a0)
	clr.b	$1B(a0)
	clr.b	$1D(a0)
	move.b	mfp_Ada+3(pc),$1f(a0) ; délai mfp avant sa prochaine
	bclr	#3,$17(a0)            ; intérruption
	move.w	#%0010000100000000,d0
	movep.w	d0,$7(a0)
	movep.w	d0,$13(a0)
	move.l	#TIMERB,$120.w
	move.l	#MFP,$134.w
	rts

Adapt	bsr	Set_Up_Hardware		  ; Code adaptatif qui découvre 
	move.l	#.TIMERB,$120.w		  ; le délai correct du timer A
	stop	#$2300			          ; pour l'obtention d'un over-
	stop	#$2300			          ; scan
	move.l	#VBL,$70.w
.again	moveq	#1,d2
.again2	moveq	#0,d1
.attente_fin_écran			      ; Attente que les 199 lignes
	tst.b	d1			              ; d'overscan aient été montrés
	beq.s	.attente_fin_écran
	move.l	Final_Screen_Address(pc),d0	; Test par rapport au
	and.l	#$ffffff,d0           ; compteur vidéo pour savoir si 
	move.l	$ffff8200.w,d1      ; l'overscan a bien été décleché
	lsl.w	#8,d1	
	and.l	#$ffff00,d1
	sub.l	d1,d0
	cmp.l	#199230,d0
	bpl.s	.Ok
	dbra	d2,.again2		        ; on fait le test 2 fois pour
	subq.b	#1,mfp_Ada+3		    ; être sûr. Sinon, on décrémente
	bne.s	.again			          ; le délai.
	bra	Adapt
.Ok	subq.b	#1,mfp_Ada+3
	move.w	#$2700,sr
	rts

.TIMERB	clr.b	$fffffa19.w     ; Intérruption locale de timer B qui
	clr.b	$fffffa1B.w           ; s'assure que seuls 199 lignes
	clr.l	$fffffa0a.w           ; d'overscan sont affichés.
.loop	move.b	(a1),d1         ; Attente de la fin de la ligne 199
	cmp.b	(a1),d1
	bne.s	.loop
	movep.l	-6(a1),d1           ; sauvegarde addresse écran atteinte
	move.l	d1,Final_Screen_Address
	moveq	#-1,d1
	rte

TIMERB	clr.b	$fffffa19.w     ; Intérruption  TimerB
	clr.b	$fffffa1B.w           ; qui arrête l'intérruption
	clr.l	$fffffa0a.w           ; Timer A d'overscan
	move.w	d6,$6C.w
RTE rte

VBL move	#$2700,sr           ; La Vbl qui initialise les
	move.b	#200-1,$fffffa21.w	; registres et commence
	move.b	#8,$fffffa1B.w		  ; l'overscan
	moveq	#0,d6
.sync cmp.b	#$6E,$FFFF8209.w
	bmi.s	.sync
	move.l	#$920092,d0
	lea	$ffff8209.w,a1
MFP sub.b	(a1)+,d0		        ; On se synchronise par
	lsr.w	d0,d0			            ; rapport au compteur
	nop				                  ; Vidéo
	move.b	d0,(a1)			        ; Overcan gauche
	move.w	a1,(a1)
	move.b	d0,$fffffa19.w      ; 16
mfp_Ada	move.b	#mfp,$fffffa1f.w; 20
	move.w	#1,d0			          ;  8
	lea	$ffff8260.w,a0		      ;  8
	move.w	a0,(a0)			        ; Stabilisateur
	clr.b	(a0)
	move.b	d0,$fffffa19.w	    ; 16
	swap	d0			              ;  4
	add.b	#230,d0			          ;  8 une ligne overscan prend
	move.w	d0,a1			          ;  4 230 octets calcul de la
	swap	d0			              ;  4 prochaine adresse écran
	move.w	a1,d0			          ;  4 pour se synchroniser la
	lea	$ffff8209.w,a1		      ;  8 prochaine fois
	move.w	a0,(a0)			        ; Overcan droite
	clr.b	(a0)
	rte
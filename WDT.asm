IniWDT:
	cli
	push OSRG
	wdr
	ldi	OSRG,(1<<WDCE)|(1<<WDE)
	out	WDTCSR,OSRG
	ldi	OSRG,(1<<WDE)|(1<<WDP2)|(1<<WDP1)|(1<<WDP0)
	out	WDTCSR,OSRG
	pop OSRG
	sei
ret

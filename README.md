What's this?
-----
Just an evening project to code up an animated moire pattern in x86 assembly for real mode DOS. 
The assembled binary is just 330 bytes. 

How to run
------
For convenience [moire.asm](src/moire.asm) is written in [MASM](https://en.wikipedia.org/wiki/Microsoft_Macro_Assembler) 
syntax but is easy to port to NASM/FASM. 

To compile (using MASM 6.11 or higher)

`ml moire.asm`

The most convenient way to run is likely through [DOSBox](https://www.dosbox.com/). To launch
in the DOS command prompt, type

`moire.com` 

You should see the following output

![B&W](docs/moire_bw.png)



# my\_hdmi\_device

**my\_hdmi\_device** is an implementation inspired by the FPGA4Fun tutorials, ULX3S DVI (vga2dvi) examples, and Larry’s HDMI BlackIceMX example. I learned by reading the code, although I didn’t fully understand everything at first. That’s why I rewrote the TMDS encoder directly from the DVI standard (Page 29) — without any problems. This helped me understand TMDS encoding, why we use LVDS, the challenges involved, and how 8b/10b encoding fits into the bigger picture.

The idea of shifting and using a faster clock appears in all implementations I studied. I also learned about DDR and SDR transmission. 🙂 For iCE40, I learned from MyStorm and Larry’s HDMI example code. The VGA “balls and stars” demo technique I picked up from Steven Hugg’s *Designing Video Game Hardware in Verilog*.

I borrowed parts of the VGA timing calculation from the ULX3S example code, because usually these values are just shown as fixed tables. I wrote everything from scratch over the Christmas holidays, using the HDMI PMOD from Luke Wren (a gift from UltraEmbedded).

I want to share what I figured out and got working. Maybe this code can be a new base for other projects. Just use `tmds_encoder`, `hdmi_device.h`, and learn from the top module — then you’ll be ready for your next project.

---

## Supported Boards

This code runs on **BlackIceMX** and **ULX3S-85F** (you can adjust the Makefile to generate fewer “balls” if needed). I don’t want to go too deep into the details, because I want to explore many FPGA designs in the future. But everything starts with the basics.

I used this PMOD for iCE40-based FPGAs:
👉 [https://github.com/Wren6991/DVI-PMOD](https://github.com/Wren6991/DVI-PMOD)

---

## TODO

* HDMI audio (island mode)

---

## Build Instructions

**ULX3S:**
make prog

**BlackIceMX:**
make -f Makefile.blackicemx prog

**Icoboard:**
make -f Makefile.icoboard prog

**iCEstick:**
cd icestick\_\_hack
make prog

**Arty7:**
make -f Makefile.arty7 prog
⚠️ Currently not working. Use Vivado instead.
Enable with:
`define ARTY7`
DDR/SDR both work.

**Colorlight i5:**
make -f Makefile.colorlighti5 prog

**Tang Nano 4K:**
`define NANO_4K`
Open project file:
nano4k/my\_hdmi\_nano/my\_hdmi\_nano.gprj

---

Have fun!

**Hirosh**

![hdmi](hdmi.jpg)



AR = arm-none-eabi-ar
ARFLAGS = rcs
hw/$(TARGET)/lib.o: src/main.s src/lib.s src/latest.s

hw/$(TARGET)/hal.a: hw/$(TARGET)/hal.o
	$(AR) $(ARFLAGS) ./$@ $<

run: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s

debug: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s -S

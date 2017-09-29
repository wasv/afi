hw/$(TARGET)/lib.o: src/main.s src/lib.s src/latest.s

run: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s

debug: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s -S

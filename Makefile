TARGET=qemu-virt

OBJS=src/main.o src/lib.o hw/$(TARGET)/startup.o hw/$(TARGET)/hal.o

.PHONY: all run debug clean-all
all: out/$(TARGET)-main.elf

%.o: %.s src/macros.i
	arm-none-eabi-as -g $< -o $@
%.o: %.c
	arm-none-eabi-gcc -c -g $< -c -o $@

out/$(TARGET)-main.elf: hw/$(TARGET)/$(TARGET).ld $(OBJS)
	@mkdir -p out/
	arm-none-eabi-ld -T hw/$(TARGET)/$(TARGET).ld $(OBJS) -o $@

%.bin: %.elf
	arm-none-eabi-objcopy -O binary $< $@
.PRECIOUS: %.elf

clean-all:
	rm -vrf out/
	find . -name *.o -delete -print

run: out/$(TARGET)-main.elf
	qemu-system-arm -M virt -kernel $< -nographic -s

debug: out/$(TARGET)-main.elf
	qemu-system-arm -M virt -kernel $< -nographic -s -S

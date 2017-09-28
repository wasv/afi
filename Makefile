AS=arm-none-eabi-as
TARGET=qemu-virt

OBJS=hw/$(TARGET)/hal.o hw/$(TARGET)/lib.o

.PHONY: all run debug clean clean-all $(TARGET)

all: out/$(TARGET).elf

$(TARGET): out/$(TARGET).elf out/$(TARGET).hex

hw/$(TARGET)/lib.o: src/main.s src/lib.s src/latest.s

out/$(TARGET).elf: hw/$(TARGET)/$(TARGET).ld $(OBJS)
	@mkdir -p out/
	arm-none-eabi-ld -T hw/$(TARGET)/$(TARGET).ld $(OBJS) -o $@

%.bin: %.elf
	arm-none-eabi-objcopy -O binary $< $@
%.hex: %.elf
	arm-none-eabi-objcopy -O ihex $< $@
.PRECIOUS: %.elf

clean:
	find . -name *.o -delete -print
clean-all:
	rm -vrf out/

run: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s

debug: out/$(TARGET).elf
	qemu-system-arm -M virt -kernel $< -nographic -s -S

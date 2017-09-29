AS=arm-none-eabi-as
TARGET?=qemu-virt

OBJS=hw/$(TARGET)/hal.o hw/$(TARGET)/lib.o

all: out/$(TARGET).elf

include hw/$(TARGET)/Makefile

.PHONY: all run debug clean clean-all $(TARGET)

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

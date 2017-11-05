AS=arm-none-eabi-as
TARGET?=qemu-virt

OBJS=hw/$(TARGET)/lib.o
HAL=hw/$(TARGET)/hal.a

all: out/$(TARGET).elf

include hw/$(TARGET)/Makefile

.PHONY: all run debug clean clean-all $(TARGET)

$(TARGET): out/$(TARGET).elf out/$(TARGET).hex

hw/$(TARGET)/lib.o: src/main.s src/lib.s src/latest.s

out/afi.a: src/main.s
	@mkdir -p out/
	$(AS) $(ASFLAGS) $^ -o obj/afi.o
	arm-none-eabi-ar rcs $@ obj/afi.o

out/$(TARGET).elf: hw/$(TARGET)/$(TARGET).ld $(OBJS) $(HAL)
	@mkdir -p out/
	arm-none-eabi-ld -T hw/$(TARGET)/$(TARGET).ld $(OBJS) $(HAL) -o $@

%.bin: %.elf
	arm-none-eabi-objcopy -O binary $< $@
%.hex: %.elf
	arm-none-eabi-objcopy -O ihex $< $@
.PRECIOUS: %.elf

clean:
	find . -name *.o -delete -print
	find . -name *.d -delete -print
clean-all:
	rm -vrf out/

NAME = hello

$(NAME).8xk: $(NAME).hex
	rabbitsign -g -k ../lib/0104.key $(NAME).hex

$(NAME).hex: $(NAME).asm
	spasm -T -I ../lib/spasm/ $(NAME).asm $(NAME).hex

clean:
	rm -f $(NAME).8xk
	rm -f $(NAME).hex
	rm -f $(NAME).lst

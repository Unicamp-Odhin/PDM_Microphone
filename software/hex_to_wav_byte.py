import wave
import sys
import struct

# Configurações do arquivo WAV
SAMPLE_RATE = 3515 * 36  # Frequência de amostragem (em Hz)
NUM_CHANNELS = 1     # Número de canais (1 = mono, 2 = estéreo)
SAMPLE_WIDTH = 1     # Largura de amostra (em bytes, 2 = 16 bits)

def hex_para_int_complemento_2(hex_valor, num_bits=16):
    # Converte o valor hexadecimal para inteiro (base 16)
    valor_int = int(hex_valor, 16)
    
    # Se o valor for maior ou igual a 2^(num_bits - 1), ele é negativo (complemento de 2)
    if valor_int >= 2**(num_bits - 1):
        valor_int -= 2**num_bits
    
    return valor_int


def hex_to_wav(input_file, output_file):
    with open(input_file, 'r') as f:
        hex_lines = f.readlines()


    audio_data = []
    for line in hex_lines:
        sample = int(line, 16)
        #if sample >= 0x80:  # Se o número é negativo em complemento de dois
        #    sample -= 0x100

        audio_data.append(sample)


    with wave.open(output_file, 'w') as wav_file:
        wav_file.setnchannels(NUM_CHANNELS)
        wav_file.setsampwidth(SAMPLE_WIDTH)
        wav_file.setframerate(SAMPLE_RATE)

        #sample = max(0, min(255, sample))  # Garante que está no intervalo válido
        for sample in audio_data:
            wav_file.writeframes(struct.pack('<B', sample))  # '<B' = little-endian, 16 bits

    print(f"Arquivo WAV gerado: {output_file}")

if __name__ == "__main__":
    input_file = sys.argv[1]
    output_file = input_file.replace(".hex", ".wav")
    hex_to_wav(input_file, output_file)

#if __name__ == "__main__":
#    for n in range(0, 1):
#        os.makedirs("wav", exist_ok=True)
#        input_file = "output.hex"
#        output_file = input_file.replace(".hex", ".wav").replace("hex/", "wav/")
#        hex_to_wav(input_file, output_file)
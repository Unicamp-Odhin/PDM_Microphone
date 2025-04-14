import wave
import sys
import struct
import os

# Configurações do arquivo WAV
SAMPLE_RATE = 3515 * 15  # Frequência de amostragem (em Hz) // 60 dividido pela contante
NUM_CHANNELS = 1         # Número de canais (1 = mono, 2 = estéreo)
SAMPLE_WIDTH = 1         # Largura de amostra (em bytes, 2 = 16 bits)

def hex_para_int_complemento_2(hex_valor, num_bits=16):
    valor_int = int(hex_valor, 16)
    if valor_int >= 2**(num_bits - 1):
        valor_int -= 2**num_bits
    return valor_int

def hex_to_wav(input_file, output_file):
    with open(input_file, 'r') as f:
        hex_lines = f.readlines()

    audio_data = []

    # Processa as linhas de 3 em 3
    for i in range(0, len(hex_lines) - 3, 4):
        amostras = [
            hex_para_int_complemento_2(hex_lines[i].strip()),
            hex_para_int_complemento_2(hex_lines[i + 1].strip()),
            hex_para_int_complemento_2(hex_lines[i + 2].strip()),
            hex_para_int_complemento_2(hex_lines[i + 3].strip()),
            #hex_para_int_complemento_2(hex_lines[i + 4].strip()),
            #hex_para_int_complemento_2(hex_lines[i + 5].strip())
        ]
        media = sum(amostras) // 4  # Média inteira
        audio_data.append(media)

    with wave.open(output_file, 'w') as wav_file:
        wav_file.setnchannels(NUM_CHANNELS)
        wav_file.setsampwidth(SAMPLE_WIDTH)
        wav_file.setframerate(SAMPLE_RATE)

        for sample in audio_data:
            sample_8bit = int((sample + 32768) / 256)
            sample_8bit = max(0, min(255, sample_8bit))  # Garante que está no intervalo válido
            wav_file.writeframes(struct.pack('<B', sample_8bit))  # '<h' = little-endian, 16 bits

    print(f"Arquivo WAV gerado: {output_file}")

if __name__ == "__main__":
    input_file = sys.argv[1]
    output_file = input_file.replace(".hex", ".wav")
    hex_to_wav(input_file, output_file)

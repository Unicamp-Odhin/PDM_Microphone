import spidev
import wave
import struct

# Parâmetros de leitura SPI
SPI_BUS = 1
SPI_CS = 0
SPI_MAX_SPEED = 350000
SPI_MODE = 0
CHUNK_SIZE = 4096  # Ler 4096 bytes por vez para não sobrecarregar a memória
TOTAL_BYTES = 524288

# Nome do arquivo WAV a ser gerado
OUTPUT_FILENAME = 'output.wav'

# Configurar o dispositivo SPI
spi = spidev.SpiDev()
spi.open(SPI_BUS, SPI_CS)
spi.max_speed_hz = SPI_MAX_SPEED
spi.mode = SPI_MODE

# Criar o arquivo WAV
with wave.open(OUTPUT_FILENAME, 'wb') as wav_file:
    # Parâmetros WAV: 1 canal, 2 bytes por amostra (16 bits), 44100 Hz
    wav_file.setnchannels(1)
    wav_file.setsampwidth(2)
    wav_file.setframerate(16000)

    bytes_read = 0
    data = bytearray()

    while bytes_read < TOTAL_BYTES:
        # Quantidade de bytes a serem lidos nesta iteração
        bytes_to_read = min(CHUNK_SIZE, TOTAL_BYTES - bytes_read)

        # Ler os bytes do SPI
        response = spi.xfer2([0x00] * bytes_to_read)

        # Adicionar os bytes lidos ao buffer de dados
        data.extend(response)
        bytes_read += bytes_to_read

    # Converter os bytes em amostras de 16 bits (pouco significativo primeiro)
    samples = []
    for i in range(0, len(data), 2):  # Ler 2 bytes por amostra
        if i + 1 < len(data):
            # Combina os bytes LSB e MSB
            sample = data[i] | (data[i + 1] << 8)

            # Converte para formato signed 16-bit
            if sample >= 0x8000:
                sample -= 0x10000

            # Ignora o ponto se for 16'h0000
            samples.append(sample)

    # Escrever os samples no arquivo WAV
    wav_file.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

spi.close()

print(f"Arquivo WAV '{OUTPUT_FILENAME}' gerado com sucesso!")

import spidev

# Parâmetros de leitura SPI
SPI_BUS = 1
SPI_CS = 0
SPI_MAX_SPEED = 3000000
SPI_MODE = 0
CHUNK_SIZE = 4096  # Ler 4096 bytes por vez para não sobrecarregar a memória
# TOTAL_BYTES = 131072
TOTAL_BYTES = 8388608

# Nome do arquivo de dump hexadecimal
OUTPUT_FILENAME = 'output.hex'

# Configurar o dispositivo SPI
spi = spidev.SpiDev()
spi.open(SPI_BUS, SPI_CS)
spi.max_speed_hz = SPI_MAX_SPEED
spi.mode = SPI_MODE

# Criar o arquivo hexadecimal
with open(OUTPUT_FILENAME, 'w') as hex_file:
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

    # Escrever os dados em formato hexadecimal (16 bits por linha)
    for i in range(0, len(data) - 1, 2):  # Passa por pares de bytes
        # Combina os bytes LSB e MSB
        sample = data[i] | ((data[i + 1] << 8))

        # Escrever o valor em hexadecimal (16 bits por linha)
        hex_file.write(f'{sample:04X}\n')

spi.close()

print(f"Dump hexadecimal salvo no arquivo '{OUTPUT_FILENAME}' com sucesso!")

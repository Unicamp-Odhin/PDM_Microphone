import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from scipy.io.wavfile import write
import numpy as np


def hex_to_bin(hex_str):
    # Converte um valor hexadecimal para uma string binária de tamanho fixo (16 bits)
    return bin(int(hex_str, 16))[2:].zfill(16)


def read_hex_file(filename):
    # Lê o arquivo e converte cada linha em binário
    pdm_bits = []
    with open(filename, 'r') as file:
        for line in file:
            hex_value = line.strip()
            if hex_value:
                bin_value = hex_to_bin(hex_value)
                pdm_bits.extend([int(bit) for bit in bin_value])
    return pdm_bits


def pdm_to_pcm(pdm_bits, sample_rate=3072000, target_sample_rate=48000):
    # Filtro FIR passa-baixas
    fir_filter = np.ones(64) / 64  # Filtro de média simples
    pcm_signal = np.convolve(pdm_bits, fir_filter, mode='valid')

    # Downsampling para a taxa de amostragem desejada
    decimation_factor = sample_rate // target_sample_rate
    pcm_signal = pcm_signal[::decimation_factor]

    # Normaliza o áudio para o intervalo de -1 a 1
    pcm_signal = (pcm_signal - np.min(pcm_signal)) / (np.max(pcm_signal) - np.min(pcm_signal))
    pcm_signal = 2 * pcm_signal - 1

    return pcm_signal


def save_to_wav(pcm_signal, target_sample_rate=48000, output_file='output.wav'):
    # Converte o sinal PCM para inteiros de 16 bits e salva em um arquivo .wav
    pcm_signal_int = np.int16(pcm_signal * 32767)
    write(output_file, target_sample_rate, pcm_signal_int)
    print(f"Áudio salvo como {output_file}")


def plot_pdm(pdm_bits, window_size=1000):
    # Configura o gráfico
    fig, ax = plt.subplots()
    plt.subplots_adjust(bottom=0.25)

    # Mostra apenas uma janela do sinal
    l, = plt.plot(pdm_bits[:window_size], linestyle='-', marker='', color='blue')
    ax.set_title('Sinal PDM Extraído do Arquivo HEX')
    ax.set_xlabel('Amostra')
    ax.set_ylabel('Nível PDM (0 ou 1)')
    ax.grid(True)

    # Adiciona um slider para navegar
    ax_slider = plt.axes([0.25, 0.1, 0.65, 0.03])
    slider = Slider(ax_slider, 'Posição', 0, len(pdm_bits) - window_size, valinit=0, valstep=1)

    def update(val):
        pos = int(slider.val)
        l.set_ydata(pdm_bits[pos:pos + window_size])
        l.set_xdata(range(pos, pos + window_size))
        ax.relim()
        ax.autoscale_view()
        plt.draw()

    slider.on_changed(update)

    plt.show()


def main():
    # Nome do arquivo .hex
    filename = 'audios/output.hex'

    # Lê o arquivo e obtém os bits PDM
    pdm_bits = read_hex_file(filename)

    # Plota o sinal PDM
    plot_pdm(pdm_bits, window_size=1000)

    # Converte o PDM para PCM
    pcm_signal = pdm_to_pcm(pdm_bits)

    # Salva o áudio convertido
    save_to_wav(pcm_signal)


if __name__ == "__main__":
    main()

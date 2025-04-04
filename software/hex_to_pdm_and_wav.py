import matplotlib.pyplot as plt
from matplotlib.widgets import Slider
from scipy.io.wavfile import write
from scipy.signal import firwin, lfilter, sosfilt, butter, iirnotch, medfilt, welch
import numpy as np
import argparse
from scipy.fft import fft, fftfreq
from padasip.filters import FilterRLS


def hex_to_bin(hex_str):
    return bin(int(hex_str, 16))[2:].zfill(16)


def read_hex_file(filename):
    pdm_bits = []
    with open(filename, 'r') as file:
        for line in file:
            hex_value = line.strip()
            if hex_value:
                bin_value = hex_to_bin(hex_value)
                pdm_bits.extend([int(bit) for bit in bin_value])
    return pdm_bits


def pdm_to_pcm(pdm_bits, sample_rate, target_sample_rate, fir_size, cutoff_hz, butter_order, notch_freq, notch_q, medfilt_size):
    # Filtro FIR
    fir_filter = firwin(fir_size, cutoff_hz / (sample_rate / 2), window='hamming')
    filtered_signal = lfilter(fir_filter, 1.0, pdm_bits)

    # Filtro Butterworth
    sos = butter(butter_order, cutoff_hz / (sample_rate / 2), btype='low', output='sos')
    filtered_signal = sosfilt(sos, filtered_signal)

    # Filtro Notch
    if notch_freq > 0:
        b_notch, a_notch = iirnotch(notch_freq / (sample_rate / 2), notch_q)
        filtered_signal = lfilter(b_notch, a_notch, filtered_signal)

    # Filtro Mediano
    if medfilt_size > 1:
        filtered_signal = medfilt(filtered_signal, kernel_size=medfilt_size)

    # Filtro Adaptativo (RLS)
    rls_filter = FilterRLS(n=1, mu=0.99)
    filtered_signal_rls = []

    for sample in filtered_signal:
        output = rls_filter.predict(np.array([sample]))  # Passe como uma lista de um único elemento
        filtered_signal_rls.append(output)

    filtered_signal = np.array(filtered_signal_rls).flatten()


    # Decimação
    decimation_factor = sample_rate // target_sample_rate
    pcm_signal = filtered_signal[::decimation_factor]

    # Normalização
    pcm_signal = (pcm_signal - np.min(pcm_signal)) / (np.max(pcm_signal) - np.min(pcm_signal))
    pcm_signal = 2 * pcm_signal - 1

    return pcm_signal


def save_to_wav(pcm_signal, target_sample_rate, output_file):
    pcm_signal_int = np.int16(pcm_signal * 32767)
    write(output_file, target_sample_rate, pcm_signal_int)
    print(f"Áudio salvo como {output_file}")


def plot_pdm(pdm_bits, window_size):
    fig, ax = plt.subplots()
    plt.subplots_adjust(bottom=0.25)

    l, = plt.plot(pdm_bits[:window_size], linestyle='-', marker='', color='blue')
    ax.set_title('Sinal PDM Extraído do Arquivo HEX')
    ax.set_xlabel('Amostra')
    ax.set_ylabel('Nível PDM (0 ou 1)')
    ax.grid(True)

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


def plot_fft(pcm_signal, target_sample_rate):
    N = len(pcm_signal)
    yf = fft(pcm_signal)
    xf = fftfreq(N, 1 / target_sample_rate)

    plt.figure()
    plt.plot(xf[:N//2], np.abs(yf[:N//2]))
    plt.title('FFT do Sinal PCM')
    plt.xlabel('Frequência (Hz)')
    plt.ylabel('Amplitude')
    plt.grid()
    plt.show()


def main():
    parser = argparse.ArgumentParser(description="Conversor de PDM para PCM com filtros configuráveis")
    parser.add_argument('filename', type=str, help='Arquivo .hex com dados PDM')
    parser.add_argument('--sample_rate', type=int, default=3072000, help='Taxa de amostragem do sinal PDM (default: 3072000 Hz)')
    parser.add_argument('--target_sample_rate', type=int, default=48000, help='Taxa de amostragem alvo para áudio PCM (default: 48000 Hz)')
    parser.add_argument('--fir_size', type=int, default=501, help='Tamanho do filtro FIR (default: 501)')
    parser.add_argument('--cutoff_hz', type=float, default=15000, help='Frequência de corte do filtro (default: 15000 Hz)')
    parser.add_argument('--butter_order', type=int, default=5, help='Ordem do filtro Butterworth (default: 5)')
    parser.add_argument('--notch_freq', type=float, default=0, help='Frequência central do filtro notch (0 para desativar)')
    parser.add_argument('--notch_q', type=float, default=30, help='Qualidade do filtro notch (default: 30)')
    parser.add_argument('--medfilt_size', type=int, default=1, help='Tamanho do filtro mediano (1 para desativar)')
    parser.add_argument('--output_file', type=str, default='output.wav', help='Nome do arquivo de saída (default: output.wav)')
    parser.add_argument('--window_size', type=int, default=1000, help='Tamanho da janela para visualização do sinal PDM (default: 1000)')

    args = parser.parse_args()

    pdm_bits = read_hex_file(args.filename)
    plot_pdm(pdm_bits, args.window_size)
    pcm_signal = pdm_to_pcm(pdm_bits, args.sample_rate, args.target_sample_rate, args.fir_size, args.cutoff_hz, args.butter_order, args.notch_freq, args.notch_q, args.medfilt_size)
    save_to_wav(pcm_signal, args.target_sample_rate, args.output_file)
    plot_fft(pcm_signal, args.target_sample_rate)


if __name__ == "__main__":
    main()

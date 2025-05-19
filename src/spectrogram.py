import librosa
import matplotlib.pyplot as plt
import numpy as np

def stft(signal, window_size, hop_length):
    n_frames = 1 + (len(signal) - window_size)//hop_length
    stft_matrix = np.empty((window_size//2 + 1, n_frames), dtype=complex)

    for i in range(n_frames):
        frame = signal[i*hop_length: i*hop_length + window_size]
        windowed_frame = frame * np.hamming(window_size)
        stft_matrix[:, i] = np.fft.rfft(windowed_frame)

    return stft_matrix

def plot_spectrogram(stft_matrix, sample_rate, hop_length):
    magnitude_spectrogram = np.abs(stft_matrix)
    log_spectrogram = librosa.amplitude_to_db(magnitude_spectrogram)

    plt.figure()
    librosa.display.specshow(log_spectrogram, sr=sample_rate, hop_length=hop_length, x_axis='time', y_axis='linear')
    plt.colorbar(format='%+2.0f dB')
    plt.title('Espectrograma')
    plt.show()

def main():
    for file in ['dump.wav', 'dump1.wav', 'dump2.wav', 'dump3.wav', 'dump4.wav', 'dump9.wav']:
        signal, sample_rate = librosa.load(file)
    
        # Plotando a forma de onda:
        plt.figure()
        librosa.display.waveshow(signal, sr=sample_rate)
        plt.title('Forma de Onda Enunciada')
        plt.show()
    
        window_size = 1024
        hop_length = 512
        stft_matrix = stft(signal, window_size, hop_length)
        plot_spectrogram(stft_matrix, sample_rate, hop_length)


if __name__ == '__main__':
    main()


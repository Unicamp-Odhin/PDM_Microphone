import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq

# Carregar os dados do arquivo .hex
filename = "dump.hex"
with open(filename, "r") as file:
    data = np.array([int(line.strip(), 16) for line in file])

# Converter os dados para valores com sinal (caso sejam 16 bits)
data = np.int16(data)

# Plotar o sinal bruto
plt.figure(figsize=(12, 6))
plt.plot(data, label="Sinal Bruto")
plt.title("Sinal Bruto")
plt.xlabel("Amostras")
plt.ylabel("Amplitude")
plt.legend()
plt.show()

# Remover picos estranhos
limite = np.mean(data) + 5 * np.std(data)
data_suave = np.where(np.abs(data) > limite, np.mean(data), data)

# Plotar o sinal após remoção de picos
plt.figure(figsize=(12, 6))
plt.plot(data_suave, label="Sinal Suavizado", color="orange")
plt.title("Sinal Após Remoção de Picos")
plt.xlabel("Amostras")
plt.ylabel("Amplitude")
plt.legend()
plt.show()

# Parâmetros do sinal
fs = 12000  # Frequência de amostragem (Hz)
N = len(data_suave)  # Número total de amostras

# Aplicar FFT no sinal suavizado
fft_data = fft(data_suave)
frequencias = fftfreq(N, 1/fs)
magnitude = np.abs(fft_data)[:N//2]

# Identificar frequência dominante
indice_dominante = np.argmax(magnitude)
frequencia_dominante = frequencias[indice_dominante]
magnitude_dominante = magnitude[indice_dominante]

# Plotar o espectro de frequências
plt.figure(figsize=(12, 6))
plt.plot(frequencias[:N//2], magnitude)
plt.title(f"Espectro de Frequências - Freq. Dominante: {frequencia_dominante:.2f} Hz (Magnitude: {magnitude_dominante:.2f})")
plt.xlabel("Frequência (Hz)")
plt.ylabel("Magnitude")
plt.show()

# Exibir frequência dominante
print(f"Frequência dominante estimada: {frequencia_dominante:.2f} Hz")

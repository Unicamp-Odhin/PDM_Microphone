import numpy as np
from scipy.signal import find_peaks
import sys

def detectar_frequencia(arquivo_hex, taxa_amostragem):
    # Lê e converte os dados
    with open(arquivo_hex) as f:
        dados = [int(linha.strip(), 16) for linha in f if linha.strip()]
    
    # Converte para array NumPy
    sinal = np.array(dados)

    # Remove zeros antes de calcular o mínimo e a média
    sinal_sem_zeros = sinal[sinal != 0]
    
    if sinal_sem_zeros.size == 0:
        print("Todos os valores são zero.")
        return

    # Menor valor
    menor_valor = np.min(sinal_sem_zeros)
    print(f"Menor valor lido (ignorando 0): {menor_valor} (0x{menor_valor:X})")

    # Média dos menores valores
    media_menores = np.mean(sinal_sem_zeros)
    print(f"Média dos menores valores (ignorando 0): {media_menores:.2f} (0x{int(media_menores):X})")

    # Detecta picos
    picos, _ = find_peaks(sinal)

    if len(picos) < 2:
        print("Poucos picos detectados para estimar a frequência.")
        return

    # Calcula os intervalos (em amostras) entre os picos
    intervalos = np.diff(picos)

    # Converte intervalos para tempo em segundos
    tempos = intervalos / taxa_amostragem

    # Calcula frequências individuais e tira a média
    freq_média = np.mean(1 / tempos)

    print(f"Frequência estimada: {freq_média:.2f} Hz")

    # Calcula os deltas do sinal (diferença entre amostras consecutivas)
    deltas = np.diff(sinal)
    media_deltas = np.mean(np.abs(deltas))
    print(f"Média dos deltas do sinal: {media_deltas:.2f}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Uso: python detectar_freq.py arquivo.hex taxa_amostragem")
    else:
        arquivo = sys.argv[1]
        taxa = float(sys.argv[2])
        detectar_frequencia(arquivo, taxa)

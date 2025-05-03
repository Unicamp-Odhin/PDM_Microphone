import numpy as np
import matplotlib.pyplot as plt


def rectangular_window(M):
    w = np.ones(M)
    return w


# Parâmetro M
M = 64

# Calcula a janela de Rectangular
w = rectangular_window(M)

# Imprime os coeficientes
print('Coeficientes da janela Retangular:')
print(w.tolist())

# Plota a janela
plt.figure(figsize=(10, 4))
plt.plot(w, marker='o')
plt.title(f'Janela Retangular (M = {M})')
plt.xlabel('n')
plt.ylabel('w(n)')
plt.grid(True)
plt.tight_layout()
plt.show()

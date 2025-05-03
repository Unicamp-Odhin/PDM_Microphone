import os
import sys
from pocketsphinx import Decoder, Config

MODEL_PATH = os.path.expanduser('~/eda/pt-br-pocketsphinx/pt-br')

config = Config()
config.set_string('-hmm', os.path.join(MODEL_PATH, 'hmm'))
config.set_string('-dict', os.path.join(MODEL_PATH, 'pt-br.dict'))
config.set_string(
    '-lm', os.path.join(MODEL_PATH, 'pt-br.lm')
)  # após extrair o .tar.gz

decoder = Decoder(config)


def reconhecer_audio(wav_file):
    decoder.start_utt()
    with open(wav_file, 'rb') as f:
        while True:
            buf = f.read(1024)
            if buf:
                decoder.process_raw(buf, False, False)
            else:
                break
    decoder.end_utt()

    hypothesis = decoder.hyp()
    if hypothesis is not None:
        print('Texto reconhecido:', hypothesis.hypstr)
    else:
        print('Nada reconhecido.')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print('Uso: python reconhece.py arquivo.wav')
        sys.exit(1)
    reconhecer_audio(sys.argv[1])

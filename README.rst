TODO:

- Is final VR project the "backup" or "original". VR Unity Project is "backup"?

Ownaura
=======

This repository provides the implementation of an own-voice auralization system implememented at DTU's audio-visual immersion lab as presented at ICA2022_.

The Python_ scripts, MAX_ patches and Unity_ project have been tested on Windows only.

Paper:
   Find it `here <https://github.com/dtu-act/ownaura/blob/master/paper.pdf>`_.

Large files:
   Download the VR Unity project, Odeon simulation files and actually used convolutional filters from the `release page <https://github.com/dtu-act/ownaura/releases>`_.

License:
   MIT -- see the file ``LICENSE`` for details.

.. _Python: https://www.python.org/
.. _MAX: https://cycling74.com/products/max-features
.. _ICA2022: https://ica2022korea.org
.. _Unity: https://unity.com/


Project overview
----------------

Repo is structured as follows::

    .
    ├── Documentation                       # [building the userguide]
    ├── libownaura                          # [python main scripts]
    ├── Lora filters                        # [store Lora output here]
    ├── MAX                                 # [Max patches]
    ├── Room acoustic parameter measurement # [scripts for measuring effective acoustic parameters]
    ...

Getting started
---------------

Create a virtual environment with conda_ and activate it::

   conda env create -f environment.yml
   conda activate ownaura

.. _conda: https://conda.io/projects/conda/en/latest/index.html

Download the large files from release page::

   python download_files.py

Now read the `userguide <https://github.com/dtu-act/ownaura/blob/master/userguide.pdf>`_. Enjoy!

Citation
--------

If you found this  codebase useful in your research, please cite::

   @inproceedings{wistbackaVocalComfort2022,
      author       = "Wistbacka Oehlund, Greta and Heuchel, Franz M. and LYBERG AAHLANDER, Viveka and MAARTENSSON, Johan and SAHLEN, Birgitta and Brunskog, Jonas",
      title        = "Vocal comfort in simulated room acoustic environments – experimental set-up and protocol development",
      booktitle    = "Proceedings of the 24th International Congress on Acoustics",
      year         = "2022",
      pages        = "1-11",
   }







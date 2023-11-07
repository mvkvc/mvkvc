# AUTOGENERATED! DO NOT EDIT! File to edit: ../nbs/00_core.ipynb.

# %% auto 0
__all__ = ['A', 'AT', 'env_or_raise', 'merge_models', 'EmbeddingConfig', 'EmbeddingModel']

# %% ../nbs/00_core.ipynb 3
import os
from abc import ABC
from abc import abstractmethod
from typing import Any
from typing import TypeVar
from typing import Literal

import numpy as np
import torch as tch
from pydantic import BaseModel

# %% ../nbs/00_core.ipynb 4
A = TypeVar("A", bound=list[float] | np.ndarray | tch.Tensor)
AT = TypeVar("AT", bound=Literal["float", "np", "tch"])

# %% ../nbs/00_core.ipynb 5
def env_or_raise(key: str) -> str:
    var = os.environ[key]

    if var is None:
        raise EnvironmentError(f"Missing environment variable: {key}")

    return var

# %% ../nbs/00_core.ipynb 6
def merge_models(modela: BaseModel, modelb: BaseModel | None = None) -> BaseModel:
    if modelb is not None:
        merged_data = {**modela.dict(), **modelb.dict()}
        result = modelb.__class__(**merged_data)
    else:
        result = modela

    return result

# %% ../nbs/00_core.ipynb 7
class EmbeddingConfig(BaseModel):
    name: str | None = None
    key: str | None = None
    region: str | None = None
    seq_tokens: int | None = None
    rate_period: int | None = None
    rate_calls: int | None = None
    rate_tokens: int | None = None

# %% ../nbs/00_core.ipynb 8
class EmbeddingModel(ABC):
    def __init__(self, config: EmbeddingConfig | None = None) -> None:
        default_config = self._get_default_config()
        self.config = merge_models(default_config, config)

    @abstractmethod
    def _get_default_config(**kwargs) -> EmbeddingConfig:
        ...

    @abstractmethod
    def embed(text: str) -> A:
        ...

    @abstractmethod
    async def embeda(text: str) -> A:
        ...

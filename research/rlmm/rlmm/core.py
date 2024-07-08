# AUTOGENERATED! DO NOT EDIT! File to edit: ../nbs/00_core.ipynb.

# %% auto 0
__all__ = ['obj_params', 'hydra_params', 'hydra_nb']

# %% ../nbs/00_core.ipynb 4
import inspect
import os
from typing import *

from fastcore.basics import *
import yaml

# %% ../nbs/00_core.ipynb 5
def obj_params(obj: Type) -> Dict[str, Any]:
    out = {}
    for cls in reversed(inspect.getmro(obj)):
        for name, param in inspect.signature(cls.__init__).parameters.items():
            if param.default is not inspect.Parameter.empty:
                out[name] = param.default
    return out

# %% ../nbs/00_core.ipynb 8
def hydra_params(obj: Type, new_only: bool = False) -> Dict[str, Any]:
    params = obj_params(obj)
    if new_only:
        base_params = obj_params(obj.__bases__[0])
        params = {k: v for k, v in params.items() if k not in base_params}

    return params

# %% ../nbs/00_core.ipynb 11
def hydra_nb(
    obj: Union[Type, None] = None,
    path: Union[str, None] = None,
    defaults: Union[None, List[str]] = None,
    params: Union[None, Dict[str, Any]] = None,
    new_only: bool = False,
):
    if obj is None and params is None:
        raise ValueError("Both the object and params cannot be None")

    if defaults is not None:
        data = {"defaults": defaults}
    else:
        data = {}

    if obj is not None:
        obj_params = hydra_params(obj, new_only=new_only)
        data.update(obj_params)

    if params is not None:
        for param in params:
            data[param] = params[param]
        if "_target_" in params:
            data.update({"_target_": data.pop("_target_")})

    if path is not None:
        path_folder = os.path.dirname(os.path.abspath(path))
        os.makedirs(path_folder, exist_ok=True)

        with open(path, "w") as f:
            yaml.dump(data, f, sort_keys=False)

    print(yaml.dump(data, sort_keys=False))
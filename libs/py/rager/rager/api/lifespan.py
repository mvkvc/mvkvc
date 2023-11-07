# AUTOGENERATED! DO NOT EDIT! File to edit: ../../nbs/api/lifespan.ipynb.

# %% auto 0
__all__ = ['lifespan']

# %% ../../nbs/api/lifespan.ipynb 4
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from openai import AsyncOpenAI

# %% ../../nbs/api/lifespan.ipynb 6
@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.clients = {}
    app.state.clients = get_openai_compat_clients(app.state.clients)
    yield
    app.state.clients.clear()

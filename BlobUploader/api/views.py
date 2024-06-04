from django.shortcuts import render
from django.http import HttpResponse
import os
import asyncio


# Create your views here.
def test_func(request):
    return HttpResponse("hello world")

# def upload_blob(request):
#     print('uploaded to blob')
#     return HttpResponse('uploaded')
# def index(request):
#     return HttpResponse ("hello world")

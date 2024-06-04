from django.urls import path
from .views import test_func


urlpatterns = [
    path('', test_func),
    # path('upload/blob/', upload_blob)
]

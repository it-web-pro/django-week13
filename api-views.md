# Django REST Framework - Part 2

## Request objects

REST Framework จะมี class `Request` ซึ่ง extend มาจาก `HttpRequest` โดยสิ่งสำคัญของ `Request` object จะเป็น `request.data` ซึ่งคล้ายกับ `request.POST` แต่จะเหมาะกับการใช้งาน Web API มากกว่า

> - **request.POST**  # Only handles form data.  Only works for 'POST' method.
> - **request.data**  # Handles arbitrary data.  Works for 'POST', 'PUT' and 'PATCH' methods.

## Response objects

และ REST Framework จะมี `Response` ซึ่ง extend มาจาก `TemplateResponse` ซึ่งจะทำการแปลงข้อมูลเป็นในรูปแบบที่เหมาะสมสำหรับ return กลับไปให้ client

```python
return Response(data)  # Renders to content type as requested by the client.
```

## Wrapping API views

REST framework จะมี wrapper 2 ตัวที่จะช่วยให้่เราเขียน API View ได้ง่าย

1. `@api_view` ซึ่งเป็น decorator ที่ใช้สำหรับกรณี function-based views
2. class `APIView` ซึ่งจะใช้สำหรับกรณี class-based views

เราลองใช้งานกัน มาแก้ไข `snippets/views.py` กัน

```python
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from snippets.models import Snippet
from snippets.serializers import SnippetSerializer


@api_view(['GET', 'POST'])
def snippet_list(request):
    """
    List all code snippets, or create a new snippet.
    """
    if request.method == 'GET':
        snippets = Snippet.objects.all()
        serializer = SnippetSerializer(snippets, many=True)
        return Response(serializer.data)

    elif request.method == 'POST':
        serializer = SnippetSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
```

จากนั้นไปแก้ไข view `snippet_detail()` ด้วย

```python
...

@api_view(['GET', 'PUT', 'DELETE'])
def snippet_detail(request, pk):
    """
    Retrieve, update or delete a code snippet.
    """
    try:
        snippet = Snippet.objects.get(pk=pk)
    except Snippet.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'GET':
        serializer = SnippetSerializer(snippet)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = SnippetSerializer(snippet, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        snippet.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
```

**Important:** สังเกตดูว่าข้อมูลที่ส่งมาจาก client จะถูกเก็บอยู่ใน `request.data` ซึ่งจะช่วยเราจัดการข้อมูลที่ส่งมาจาก client ในรูปแบบ `json`

> มาลองเล่นโดยใช้ POSTMAN กันว่าใช้งานได้เหมือนเดิมไหม

## Class-based Views

เราสามารถใช้งาน class-based view ได้เช่นกัน

แก้ไข `snippets/views.py` ดังนี้

```python
from snippets.models import Snippet
from snippets.serializers import SnippetSerializer
from django.http import Http404
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status


class SnippetList(APIView):
    """
    List all snippets, or create a new snippet.
    """
    def get(self, request, format=None):
        snippets = Snippet.objects.all()
        serializer = SnippetSerializer(snippets, many=True)
        return Response(serializer.data)

    def post(self, request, format=None):
        serializer = SnippetSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SnippetDetail(APIView):
    """
    Retrieve, update or delete a snippet instance.
    """
    def get_object(self, pk):
        try:
            return Snippet.objects.get(pk=pk)
        except Snippet.DoesNotExist:
            raise Http404

    def get(self, request, pk, format=None):
        snippet = self.get_object(pk)
        serializer = SnippetSerializer(snippet)
        return Response(serializer.data)

    def put(self, request, pk, format=None):
        snippet = self.get_object(pk)
        serializer = SnippetSerializer(snippet, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, pk, format=None):
        snippet = self.get_object(pk)
        snippet.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
```

อย่าลืมว่าถ้าเราเปลี่ยนมาใช้ class-based views แล้วจะต้องไปแก้ไข `urls.py` ด้วยนะครับ

```python
from django.urls import path
from snippets import views

urlpatterns = [
    path('snippets/', views.SnippetList.as_view()),
    path('snippets/<int:pk>/', views.SnippetDetail.as_view()),
]
```

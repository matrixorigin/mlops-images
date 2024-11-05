# use ultralytics as base images, you can use stable tag instead of latest
FROM ultralytics/ultralytics:latest

# copy the source code to /root/yolo
COPY yolo /root/yolo

# install streamlit to run yolo
RUN pip install streamlit

# change the working directory
WORKDIR /root/yolo/

# run the app
CMD ["streamlit", "run", "app.py"]

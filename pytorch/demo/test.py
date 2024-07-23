import torch
import torchvision
from PIL import Image
from torch import nn

# 要推理测试的原图片地址airplane.png是个飞机图片，dog.png是小狗图片。
# image_path = "./imgs/airplane.png"
image_path = "./imgs/dog.png"

# 打开图片
image = Image.open(image_path)
print(image)

# 将图像转换为RGB模式（如果不是RGB）
image = image.convert('RGB')

# 定义转换操作，调整图像大小为 32x32 像素，将图像转换为张量
transform = torchvision.transforms.Compose([torchvision.transforms.Resize((32, 32)),
                                            torchvision.transforms.ToTensor()])

# 应用转换操作：将定义好的转换操作应用到打开的图像上，得到转换后的张量 image。
image = transform(image)
print(image.shape)

# 加载预训练模型 (torch.load)：使用 torch.load 加载预训练的 PyTorch 模型文件 tudui_9.pth。
# 这里的tudui_9.pth替换为实模型文件路径，模型文件名称是train.py训练得到的。

# 因为输入的测试图片是cpu（tensor）类型，#而加载的模型是GPU模型，所以要进行转换
model = torch.load("tudui_9.pth", map_location=torch.device('cpu'))

# 模型推理
print(model)
image = torch.reshape(image, (1, 3, 32, 32))
model.eval()
with torch.no_grad():
    output = model(image)
print(output)

#这个就是预测那10个类别时得分最高的类别的序号：飞机的序号是0，小狗的序号是5
print("测试的图片属于的类型：{}".format(output.argmax(1)))

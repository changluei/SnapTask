import { textRecognition } from '@kit.CoreVisionKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class PickedImage {
  imageName: string = '';
  imageUri: string = '';
}

export class OcrModel {
  async pickImage(): Promise<PickedImage> {
    let options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;

    let picker = new photoAccessHelper.PhotoViewPicker();
    let result = await picker.select(options);
    let picked = new PickedImage();
    if (result.photoUris.length > 0) {
      picked.imageName = '已选择本机课程截图';
      picked.imageUri = result.photoUris[0];
    }
    return picked;
  }

  async recognizeImage(imageUri: string): Promise<string> {
    let selectedFile: fileIo.File | undefined = undefined;
    let source: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;

    try {
      await textRecognition.init();
      selectedFile = fileIo.openSync(imageUri, fileIo.OpenMode.READ_ONLY);
      source = image.createImageSource(selectedFile.fd);
      pixelMap = await source.createPixelMap();
      let result = await textRecognition.recognizeText({
        pixelMap: pixelMap
      }, {
        isDirectionDetectionSupported: true
      });
      return result.value;
    } finally {
      if (pixelMap !== undefined) {
        await pixelMap.release();
      }
      if (source !== undefined) {
        await source.release();
      }
      if (selectedFile !== undefined) {
        fileIo.closeSync(selectedFile);
      }
      await textRecognition.release();
    }
  }

  errorText(error: Object): string {
    let businessError = error as BusinessError;
    if (businessError.message.length > 0) {
      return businessError.message;
    }
    return JSON.stringify(error);
  }
}

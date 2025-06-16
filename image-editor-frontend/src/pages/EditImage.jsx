import { useState } from "react";
import { View, Flex } from "@adobe/react-spectrum";
import ImageUpload from "../components/ImageUpload";
import ImageEditor from "../components/ImageEditor/ImageEditor";

export default function EditImage({ imageUrl, setImageUrl }) { 
    const [uploadedImageId, setUploadedImageId] = useState(null);
    const [originalImageId, setOriginalImageId] = useState(null);
    const [uploadedFile, setUploadedFile] = useState(null);

    return (
      <View backgroundColor="gray-200" minHeight="100vh" width="100vw">
        <Flex direction="column" alignItems="center" gap="size-400" width="100%">
          <ImageUpload 
            setImageUrl={setImageUrl} 
            setUploadedImageId={setUploadedImageId} 
            setOriginalImageId={setOriginalImageId}
            setUploadedFile={setUploadedFile}
          />
          {imageUrl && <ImageEditor imageUrl={imageUrl} uploadedImageId={uploadedImageId} originalImageId={originalImageId}  imageFile={uploadedFile}/>}
        </Flex>
      </View>
    );  
  }
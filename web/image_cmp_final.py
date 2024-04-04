from flask import Flask, request, jsonify
import cv2
import numpy as np
import json
import warnings

warnings.filterwarnings("ignore")

app = Flask(__name__)

def mean_squared_error(image1, image2):
    error = np.sum((image1.astype('float') - image2.astype('float'))**2)
    error = error / float(image1.shape[0] * image2.shape[1])
    return error

@app.route('/compare', methods=['POST'])
def compare_images():
    data = request.get_json()

    if 'image1_path' not in data or 'image2_path' not in data:
        return jsonify({'error': 'Both image paths are required.'}), 400

    image1_path = data['image1_path']
    image2_path = data['image2_path']

    image1 = cv2.imread(image1_path)
    image2 = cv2.imread(image2_path)

    if image1 is None or image2 is None:
        return jsonify({'error': 'One or both of the images could not be loaded.'}), 400

    image1_gray = cv2.cvtColor(image1, cv2.COLOR_BGR2GRAY)
    image2_gray = cv2.cvtColor(image2, cv2.COLOR_BGR2GRAY)

    similarity = image_comparison(image1_gray, image2_gray)
    
    return jsonify(similarity)

def image_comparison(image1, image2, threshold=2500, ratio=0.75):
    try:
        # Check if the images are already grayscale
        if len(image1.shape) == 3 and image1.shape[2] == 3:
            gray_image1 = cv2.cvtColor(image1, cv2.COLOR_BGR2GRAY)
        else:
            gray_image1 = image1

        if len(image2.shape) == 3 and image2.shape[2] == 3:
            gray_image2 = cv2.cvtColor(image2, cv2.COLOR_BGR2GRAY)
        else:
            gray_image2 = image2

        # Initialize SIFT detector
        sift = cv2.SIFT_create()

        # Detect keypoints and compute descriptors
        keypoints1, descriptors1 = sift.detectAndCompute(gray_image1, None)
        keypoints2, descriptors2 = sift.detectAndCompute(gray_image2, None)

        # Initialize a Flann-based matcher
        flann = cv2.FlannBasedMatcher()
        
        # Match descriptors
        matches = flann.knnMatch(descriptors1, descriptors2, k=2)

        # Apply Lowe's ratio test to filter matches
        good_matches = []
        for m, n in matches:
            if m.distance < ratio * n.distance:
                good_matches.append(m)

        # Check if the number of good matches exceeds the threshold
        if len(good_matches) >= threshold:
            return {"similar": True, "match_count": len(good_matches)}
        else:
            return {"similar": False, "match_count": len(good_matches)}
    except Exception as e:
        return {"error": str(e)}

if __name__ == '__main__':
    app.run(debug=True)

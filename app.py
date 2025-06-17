import os
import subprocess
from setting import SERVER_HOST, SERVER_PORT, UPLOAD_DIR, OUTPUT_DIR
import flask
from flask import jsonify, send_file, request, render_template

app = flask.Flask(__name__)

@app.route('/', methods=['GET'])
def index():
    return render_template('index.html')

@app.route('/offline', methods=['POST'])
def offline_difypkg():
    try:
        # S1: 检查请求中是否有文件
        if 'file' not in request.files:
            return jsonify({"error": "No file part"}), 400

        file = request.files['file']

        # 检查文件是否有名称
        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        # 检查文件扩展名是否为 .difypkg
        if not file.filename.endswith('.difypkg'):
            return jsonify({"error": "File must be a .difypkg file"}), 400

        # S2: 保存上传的文件到 difypkg 目录
        input_file_path = os.path.join(UPLOAD_DIR, file.filename)
        file.save(input_file_path)
        # 构建输出文件名 (原文件名 + '-offline.difypkg')
        base_name = os.path.splitext(file.filename)[0]
        output_file_name = f"{base_name}-offline.difypkg"
        output_file_path = os.path.join(OUTPUT_DIR, output_file_name)

        # S3: 调用 shell 脚本进行离线打包
        script_path = os.path.join(os.getcwd(), 'script', 'plugin_repackaging.sh')

        # 执行脚本 (确保脚本有执行权限: chmod +x script/plugin_repackaging.sh)
        result = subprocess.run(
            [script_path, 'local', input_file_path],
            capture_output=True,
            text=True,
            check=True
        )

        # 检查打包后的文件是否存在
        if not os.path.exists(output_file_path):
            app.logger.error(f"打包后的文件不存在: {output_file_path}")
            app.logger.error(f"脚本输出: {result.stdout}")
            app.logger.error(f"脚本错误: {result.stderr}")
            return jsonify({"error": "打包过程失败，未生成离线包"}), 500

        # S4: 返回打包后的文件
        return send_file(
            output_file_path,
            as_attachment=True,
            download_name=output_file_name,
            mimetype='application/octet-stream'
        )

    except subprocess.CalledProcessError as e:
        app.logger.error(f"脚本执行失败: {e.stderr}")
        return jsonify({"error": f"打包脚本执行失败: {e.stderr}"}), 500
    except Exception as e:
        app.logger.error(f"处理请求时出错: {str(e)}")
        return jsonify({"error": f"处理请求时出错: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(host=SERVER_HOST, port=SERVER_PORT, debug=True)
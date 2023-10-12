import unittest
import subprocess

class DictTest(unittest.TestCase):
    def test_existing_key(self):
        data = {
            'first_sentence': 'Hello, World!\n',
            'second_sentence': 'It works on my computer\n',
            'third_sentence': 'I like to push into master\n',
            'fourth_sentence': 'Debug in production\n',
            'fifth_sentence': 'if{return}else{return} enjoyer\n'
        }
        for key in data.keys():
            try:
                output = subprocess.check_output(f'echo "{key}" | ./program', shell=True, text=True)
                self.assertEqual(data[key], output)
            except subprocess.CalledProcessError as e:
                print(f'Error: {e}')
    def test_no_key(self):
        try:
            key = 'not existing key'
            output = subprocess.check_output(f'echo "{key}" | ./program 2>/dev/null', shell=True, text=True)
            self.assertIn("There is no such key in the dictionary", output)
        except subprocess.CalledProcessError as e:
            pass
        except Exception as e:
            print(f"Error {e}")

    def test_invalid_input(self):
        try:
            key = 'test' * 200
            output = subprocess.check_output(f'echo "{key}" | ./program 2>/dev/null', shell=True, text=True)
            self.assertIn("Error: the key length is more than 255 characters", output)
        except subprocess.CalledProcessError as e:
            pass
        except Exception as e:
            print(f"Error: {e}")





if __name__ == "__main__":
    unittest.main()

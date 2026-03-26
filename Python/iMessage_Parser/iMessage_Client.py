import sqlite3
from sqlite3 import Connection, Cursor
from datetime import datetime, timedelta
import json
import os
import re


html_base_struct = """<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <style>
            html {
                background-color: #fefefe;
                width: 100%;
                min-height: 100%;
            }

            body {
                width: 98%;
                min-height: 100%;
            }

            a {
            padding-left: 10px;
            }

            .contactView {
                display: flex;
                justify-content: space-around;
                align-items: center;
                flex-direction: row;

                font-size: 18px;

                width: 100vw;
                height: 7.5rem;

                border-bottom: 1px solid #0e0e0e;
            }

            .contactView div {
                display: flex;
                justify-content: flex-start;
                align-items: center;
                flex-direction: row;

                font-size: 18px;

                width: 50vw;
                height: 7.5rem;

                border-bottom: 1px solid #0e0e0e;
            }

            .contactView p {
                text-align: end;
            }

            .contactView p {
                padding-left: 25px;
            }

            .messageBox {
                display: flex;
                justify-content: space-around;
                align-items: baseline;
                flex-direction: column;

                gap: 1rem;

                width: 100%;

                padding-top: 20px;
            }

            .messageSent {
                display: flex;
                justify-content: end;
                flex-direction: row;

                width: 100%;
                height: 5%;

                padding-right: 10px;
                padding-left: 10px;

            }

            .messageSent .iMessage {
                background-color: #1CA4ED;
            }

            .messageSent .SMS {
                background-color: #1CED67;
            }

            .messageReceived {
                display: flex;
                justify-content: start;
                flex-direction: row;

                width: 100%;
                height: 5%;

                padding-right: 10px;
                padding-left: 10px;
            }

            .messageReceived .iMessage {
                background-color: #91B1F0;
            }

            .messageReceived .SMS {
                background-color: #67D66A;
            }

            .innerMessage {
                display: flex;
                justify-content: start;
                align-items: start;
                flex-direction: column;

                border: 1px solid #0e0e0e;
                border-radius: 10px;
            }

            .message {
                display: flex;
                align-items: center;

                color: #0e0e0e;

                width: 40rem;
                max-width: 40rem;
                min-height: 2.5rem;
                height: auto;
            }

            .img-preview {
                width: 40rem;
                height: 20vh;

                object-fit: cover;   /* Bild füllt den Rahmen, überschüssige Teile abgeschnitten */
                object-position: center; /* Ausschnitt zentrieren */

                padding-left: 10px;
            }

            .messageSent .message {
                justify-content: end;
                margin-right: 20px;

                text-align: right;
            }

            .messageReceived .message {
                justify-content: start;
                margin-left: 20px;
            }

            .messageMetadata {
                display: flex;
                justify-content: flex-start;
                align-items: flex-start;
                flex-direction: column;

                margin-left: 10px;
                width: 40rem;
                max-width: 40rem;

                border-top: 1px solid #0e0e0e;

                padding-bottom: 5px;
            }

            .metadataTable {
                width: 40rem;
                table-layout: auto;
                border-collapse: separate;
            }

            .metadataTable td {
                border: 1px solid #0e0e0e;
                text-align: center;
            }
        </style>
    
"""

def apple_timestamp_to_datetime(ns_timestamp):
    # Apple epoch (01.01.2001)
    apple_epoch = datetime(2001, 1, 1)
    
    seconds = ns_timestamp / 1_000_000_000
    dt = apple_epoch + timedelta(seconds=seconds)
    return dt.strftime("%d.%m.%Y %H:%M")

class DB_Parser:

    def __init__(self, db_path: str):
        self.db_path = db_path
        self.root_path = db_path[:db_path.index("/chat.db")]
        self.folder_path = self.root_path + "/Aufbereitung"
        self.conn: Connection | None = None
        self.cursor: Cursor | None = None
        self.chat_array = []
        self.content_dict = {}
        self.contacts = {}

        os.makedirs(self.folder_path, exist_ok=True)

        self.html_colors = {
            "sms_send_green": "#1CED67",
            "iMessage_send_blue": "#1CA4ED",
            "sms_received_green": "#67D66A",
            "iMessage_recieved_blue": "#91B1F0",
            "base_white": "#fefefe",
            "text_color": "#0e0e0e"
        }

    def reset_path(self, path: str):
        if not (path):
            raise Exception("DB Path was not passed. Aborting")
        self.db_path = path

    def connect(self):
        if not self.conn:
            self.conn = sqlite3.connect(self.db_path)
            self.cursor = self.conn.cursor()

    def connect_secondary(self, db_path):
        self.conn_sec = sqlite3.connect(db_path)
        self.cursor_sec = self.conn_sec.cursor()

    def close(self):
        if self.conn:
            self.conn.close()
            self.conn = None
            self.cursor = None

    def execute(self, query: str, params: tuple = ()):
        if not self.conn:
            self.connect()
        self.cursor.execute(query, params)
        self.conn.commit()
        return self.cursor
    
    def execute_secondary(self, query: str, params: tuple = ()):
        if not self.conn_sec:
            self.connect()
        self.cursor_sec.execute(query, params)
        self.conn_sec.commit()
        return self.cursor_sec

    def select(self, table: str, columns="*", where=None, params: tuple = ()):
        sql = f"SELECT {columns} FROM {table}"
        if where:
            sql += f" WHERE {where}"

        cursor = self.execute(sql, params)
        return cursor.fetchall()
    
    def select_secondary(self, table: str, columns="*", where=None, params: tuple = ()):
        sql = f"SELECT {columns} FROM {table}"
        if where:
            sql += f" WHERE {where}"

        cursor = self.execute_secondary(sql, params)
        return cursor.fetchall()
    
    def slice_chat_guid(self, guid: str):
        service_type = guid[:guid.index(';')]
        endpoint = guid[guid.index(";") + 3:]
        return [service_type, endpoint]
    
    def add_chat_entry(self, chat_row):
        service, endpoint = self.slice_chat_guid(chat_row[1])
        last_address_handles = chat_row[11]
        chat_id = chat_row[0]
        if (last_address_handles == "None" or last_address_handles == None):
            last_address_handles = ""

        self.content_dict[chat_id] = {
            "contact": endpoint,
            "service_type": service,
            "number_used": last_address_handles,
            "messages": []
        }

    def add_message_to_chat(self, chat_id, message_row):
        # [0] iter, [2] text, [11] service, [15] date, [16] date_read, [17] date_delivered, [21] is_from_me, [26] is_read, [31] is_forward, [38]_is audio, [39] is played, [63] destination_caller_id
        text = message_row[2]
        if (text == None):
            text = ""

        message = {
            "type": "message",
            "id": message_row[0],
            "text": text,
            "service": message_row[11],
            "date": message_row[15],
            "date_read": message_row[16],
            "date_delivered": message_row[17],
            "is_from_me": message_row[21],
            "is_read": message_row[26],
            "is_forward": message_row[31],
            "destination_caller_id": message_row[63]
        }
        self.content_dict[chat_id]["messages"].append(message)

    def add_attachment_to_chat(self, chat_id, message_row, attachment_content, attachment_id):
        # [0] iter, [2] created_date, [4] filename, [5] uti
        source = attachment_content[4]
        source = source[source.index('Messages') + len('Messages') + 1:]
        data_type = attachment_content[5]

        attachment = {
            "type": "attachment",
            "id": message_row[0],
            "text": message_row[2],
            "service": message_row[11],
            "date": message_row[15],
            "date_read": message_row[16],
            "date_delivered": message_row[17],
            "is_from_me": message_row[21],
            "is_read": message_row[26],
            "is_forward": message_row[31],
            "destination_caller_id": message_row[63],
            "attachment": {
                "id": attachment_id,
                "created": attachment_content[2],
                "source": source,
                "type": data_type,
                "is_audio": message_row[38],
                "is_played": message_row[39],
            }
        }
        self.content_dict[chat_id]["messages"].append(attachment)


    def exctract_messages(self):

        self.connect()

        chat_content = self.select("chat") # [0] iter, [11] last_addressed_handle
        message_join_content = self.select("chat_message_join")
        attachment_content = self.select("attachment") 

        for chat_row in chat_content:
            self.add_chat_entry(chat_row)

        for join_row in message_join_content:
            try:
                chat_id = join_row[0]
                message_id = join_row[1]

                message_row = self.select('message', '*', f'rowid = {message_id}')
                message_row = message_row[0]

                attachment_querry = self.select('message_attachment_join', '*', f'message_id = {message_id}')

                if (len(attachment_querry) == 0):                    
                    self.add_message_to_chat(chat_id, message_row)
                    continue

                attachment_content = self.select('attachment', '*', f'rowid = {attachment_querry[0][1]}')
                self.add_attachment_to_chat(chat_id, message_row, attachment_content[0], attachment_querry[0][1])

            except Exception as e:
                # TODO log action
                pass

        print("DB parsing finished")
        self.close()

    # needs .abbu contact export
    def exctract_contacts(self, contact_folder):

        def _search_db_files(contact_folder):
            contact_db_paths = []

            for root, dirs, files in os.walk(contact_folder):
                for file in files:
                    # sort MacOS temp files 
                    if ("._" in file[0:3]):
                        continue

                    if not file.endswith(".abcddb"):
                        continue 

                    full_path = os.path.join(root, file)
                    contact_db_paths.append(full_path)
            return contact_db_paths
        
        def _extract_name_and_number(db_row, contact_dict):
            # joined col in [5]
            contact_info = db_row[5]
            #reg-edit check for numbers 
            parts = contact_info.split()
            n = len(parts)

            # Detect the repeated name block
            for i in range(1, n):
                if parts[:i] == parts[i:2*i]:
                    name_words = parts[:i]          # real name
                    numbers = parts[2*i:]           # everything after repetition
                    name = " ".join(name_words)

                    # Build dict number → {name: ...}
                    for num in numbers:
                        try:
                            if (num[0] == "+"):
                                num_sliced = num[1:]
                                num = int(num_sliced.strip())
                                contact_dict[num] = {"name": name}
                            else:
                                num = int(num.strip())
                                contact_dict[str(num)] = {"name": name}
                        except:
                            pass
                    return 

        # find contact db (.abcddb) file
        self.contact_db_paths = _search_db_files(contact_folder)

        if (len(self.contact_db_paths) < 1):
            return 
        
        for db_path in self.contact_db_paths:
            self.connect_secondary(db_path)
            try:
                db_content = self.select_secondary("ZABCDCONTACTINDEX", "*")
                if (len(db_content) < 1):
                    continue 
                
                for row in db_content:
                    _extract_name_and_number(row, self.contacts)

            except Exception as e:
                pass

    def sort_messages_by_timestamp(self):
        for key, entry in self.content_dict.items():
            entry["messages"] = sorted(
                entry["messages"],
                key=lambda m: m["date"],
                reverse=False   # True = newest first
            )

    def match_number_and_name(self):
        for key, entry in self.content_dict.items():
            contact = entry["contact"]

            if (contact[0] == "+" or contact[0] == 0):
                try: 
                    contact_sliced = contact[1:]
                    name_entry = self.contacts[str(contact_sliced)]
                    entry["contact"] += " | " + name_entry["name"]
                except Exception as e:
                    pass

                try: 
                    contact_sliced = contact[3:]
                    name_entry = self.contacts[str(contact_sliced)]
                    entry["contact"] += " | " + name_entry["name"]
                except Exception as e:
                    pass

                try: 
                    contact_sliced = contact[3:]
                    name_entry = self.contacts[str("0" + contact_sliced)]
                    entry["contact"] += " | " + name_entry["name"]
                except Exception as e:
                    pass

    def create_html(self, chat_dict, chat_id):

        def _create_message_sent(current_dict):
            message_id = current_dict["id"]
            service = current_dict["service"]
            text = current_dict["text"]
            date = current_dict["date"]
            used_number = current_dict["destination_caller_id"]
            date_string = apple_timestamp_to_datetime(date)

            return f"""
                <div class="messageSent">
                    <div class="innerMessage {service}">
                        <p class="message ">{text}</p>
                        <div class="messageMetadata"> 
                            <p> Metadata (Message ID: #{message_id})</p>
                            <table class="metadataTable">
                                <tr>
                                    <td>Type: {service}</td>
                                    <td>Sent: {date_string}</td>
                                    <td>Number used: {used_number}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>"""
        
        def _create_message_sent_attachment(current_dict):
            message_id = current_dict["id"]
            service = current_dict["service"]
            text = current_dict["text"]
            date = current_dict["date"]
            
            used_number = current_dict["destination_caller_id"]
            date_string = apple_timestamp_to_datetime(date)

            attachment_dict = current_dict["attachment"]
            source = attachment_dict["source"]
            attachment_id = attachment_dict["id"]
            attachment_type = attachment_dict["type"]

            attachment_substring = f"""<a href="../{source}" download target="_blank">
                    <p> Click To Download Attachment</p>
                </a>"""

            if (attachment_type == "public.jpeg" or attachment_type == "public.png"):
                attachment_substring = f"""
                    <a href="../{source}" target="_blank">
                        <img class="img-preview" src="../{source}">
                    </a>
                    """

            return f"""
                <div class="messageSent">
                    <div class="innerMessage {service}">
                        <p class="message ">{text}</p>
                        {attachment_substring}
                        <div class="messageMetadata"> 
                            <p> Metadata (Message ID: #{message_id})</p>
                            <table class="metadataTable">
                                <tr>
                                    <td>Type: {service}</td>
                                    <td>Sent: {date_string}</td>
                                    <td>Number used: {used_number}</td>
                                </tr>
                                <tr>
                                    <td>Attachment ID: #{attachment_id}</td>
                                    <td>Attachment Type: {attachment_type}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>"""
        
        def _create_message_received(current_dict):
            message_id = current_dict["id"]
            service = current_dict["service"]
            text = current_dict["text"]
            date_sent = current_dict["date"]
            date_read = current_dict["date_read"]
            date_sent_string = apple_timestamp_to_datetime(date_sent)
            date_read_string = apple_timestamp_to_datetime(date_read)

            if (date_read == 0):
                date_read_string = "-"

            if not (current_dict["is_read"] == 1):
                date_read_string = "unread"

            return f"""
                <div class="messageReceived">
                    <div class="innerMessage {service}">
                        <p class="message ">{text}</p>
                        <div class="messageMetadata"> 
                            <p> Metadata (Message ID: #{message_id})</p>
                            <table class="metadataTable">
                                <tr>
                                    <td>Type: {service}</td>
                                    <td>Received: {date_sent_string}</td>
                                    <td>Read: {date_read_string}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>"""
        
        def _create_message_received_attachment(current_dict):
            message_id = current_dict["id"]
            service = current_dict["type"]
            text = current_dict["text"]
            date_sent = current_dict["date"]
            date_read = current_dict["date_read"]
            date_sent_string = apple_timestamp_to_datetime(date_sent)
            date_read_string = apple_timestamp_to_datetime(date_read)

            attachment_dict = current_dict["attachment"]
            source = attachment_dict["source"]
            attachment_id = attachment_dict["id"]
            attachment_type = attachment_dict["type"]

            if (date_read == 0):
                date_read_string = "-"

            if not (current_dict["is_read"] == 1):
                date_read_string = "unread"

            attachment_substring = f"""<a href="../{source}" download target="_blank">
                    <p> Click To Download Attachment</p>
                </a>"""

            if (attachment_type == "public.jpeg" or attachment_type == "public.png"):
                attachment_substring = f"""
                    <a href="../{source}" target="_blank">
                        <img class="img-preview" src="../{source}">
                    </a>
                    """

            return f"""
                <div class="messageReceived">
                    <div class="innerMessage {service}">
                        <p class="message ">{text}</p>
                        {attachment_substring}
                        <div class="messageMetadata"> 
                            <p> Metadata (Message ID: #{message_id})</p>
                            <table class="metadataTable">
                                <tr>
                                    <td>Type: {service}</td>
                                    <td>Received: {date_sent_string}</td>
                                    <td>Read: {date_read_string}</td>
                                </tr>
                                <tr>
                                    <td>Attachment ID: #{attachment_id}</td>
                                    <td>Attachment Type: {attachment_type}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                </div>"""


        def _end_html():
            return "</div></body></html>"

        html_add = f"""
            <title>Chat: #{chat_id}</title>
            </head>
            <body>
            <div class="contactView">
                <div>
                    <p>{chat_dict["contact"]}</p>
                    <p>Messages: {len(chat_dict["messages"])}</p>
                    <p>Type: {chat_dict["service_type"]}</p>
                </div>
                <p><a href="_overview.html">Back to Overview</a></p>
            </div>
            <div class="messageBox">
            """
        
        html_string = html_base_struct + html_add

        for message in chat_dict['messages']:
            if (message["type"] == 'message'):
                if (message['is_from_me'] == 1):
                    html_string += _create_message_sent(message)
                    continue

                html_string += _create_message_received(message)
                continue

            if (message["type"] == 'attachment'):
                if (message['is_from_me'] == 1):
                    html_string += _create_message_sent_attachment(message)
                    continue

                html_string += _create_message_received_attachment(message)
                continue

        html_string += _end_html()

        with open(f"{self.folder_path}/chat_{chat_id}.html", "w", encoding="utf-8") as f:
            f.write(str(html_string))

    def create_overview_html(self):

        def _create_overview_start():
            return """
            <html>
            <head>
            <style>
                html, body {
                    width: 100%;
                    min-height: 100%;
                }

                table {
                    width: 100%;
                    table-layout: auto;
                    border-collapse: separate;

                    text-align: center;
                }

                th {
                    border: 2px solid #0e0e0e;
                }

                td {
                    border: 1px solid #0e0e0e;
                }

            </style>
            </head>
            <body>
            <div>
            <table>
            <th>Chat ID</th>
            <th>Contact</th>
            <th>Message Count</th>
            <th>Chat Type</th>
            <th>Link</th>
            """
        
        def _generate_overview_table(data):
            return f"""
            <tr>
                <td>#{data[0]}</td>
                <td>{data[1]}</td>
                <td>{data[2]} Messages</td>
                <td>{data[3]}</td>
                <td><a href="chat_{data[0]}.html" target="_blank"> Open Chat #{data[0]}</a></td>
            </tr>
            """
        
        def _create_overview_end():
            return "</table></div></body>"
        
        if not (len(self.chat_array) > 1):
            raise Exception("Chat Array has no content. Aborting")

        html_base = _create_overview_start()

        for element in self.chat_array:
            html_base += _generate_overview_table(element)
        
        html_base += _create_overview_end()

        with open(f"{self.folder_path}/_overview.html", "w", encoding="utf-8") as f:
            f.write(str(html_base))


def exctract_iMessage(path, contact_path=""):
    file_name = "raw_db_data.json"
    
    if not(path):
        print("Path invalide")
        return
        
    # path = "/Messages/chat.db"
    # contact_path = "/Contacts"
    
    db = DB_Parser(path)
    db.exctract_messages()
    db.sort_messages_by_timestamp()
    db.exctract_contacts(contact_path)

    if not (db.contacts == {}):
        print('contact matching')
        db.match_number_and_name()

    with open(f"{db.folder_path}/{file_name}", "w", encoding="utf-8") as f:
        json.dump(db.content_dict, f, indent=4)

    for chat_id, chat in db.content_dict.items():
        contact = chat["contact"]
        message_count = len(chat["messages"])
        chat_type = chat["service_type"]

        db.create_html(chat, chat_id)
        db.chat_array.append([chat_id, contact, message_count, chat_type])

    # print('All Chat HTMLs created')
    # db.create_overview_html()

# contacts DB maybe dont exists on older macOS Versions
# call >python iMessage_Client.py --path /Messages/chat.db --contacts /Contacts
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Export iMessage data")

    parser.add_argument(
        "--path",
        required=True,
        help="Pfad zur Messages DB (chat.db)"
    )

    parser.add_argument(
        "--contacts",
        required=False,
        help="Pfad zum Kontakte-Ordner"
    )

    args = parser.parse_args()

    exctract_iMessage(args.path, args.contacts)
    


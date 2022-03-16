/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.api.service.signature;

import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.IntersectionType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.types.Type;
import io.ballerina.runtime.api.types.UnionType;
import io.ballerina.stdlib.http.api.HttpUtil;

import java.util.List;

/**
 * {@code {@link HeaderRecordParam }} represents a inbound request header parameter details.
 *
 * @since sl-alpha3
 */
public class HeaderRecordParam extends HeaderParam {
    private final List<String> keys;
    private final HeaderRecordParam.FieldParam[] fields;
    private final Type type;

    public HeaderRecordParam(String token, Type type, List<String> keys, HeaderRecordParam.FieldParam[] fields) {
        super(token);
        this.type = type;
        this.keys = keys;
        this.fields = fields;
    }

    public RecordType getType() {
        return (RecordType) this.type;
    }

    public List<String> getKeys() {
        return this.keys;
    }

    public HeaderRecordParam.FieldParam getField(int index) {
        return this.fields[index];
    }

    static class FieldParam {
        private Type type;
        private boolean readonly;
        private boolean nilable;

        public FieldParam(Type fieldType, boolean readonly, boolean nilable) {
            this.type = getEffectiveType(fieldType);
            this.readonly = readonly;
            this.nilable = nilable;
        }

        Type getEffectiveType(Type paramType) {
            if (paramType instanceof UnionType) {
                List<Type> memberTypes = ((UnionType) paramType).getMemberTypes();
                this.nilable = true;
                for (Type type : memberTypes) {
                    if (type.getTag() == TypeTags.NULL_TAG) {
                        continue;
                    }
                    return type;
                }
            } else if (paramType instanceof IntersectionType) {
                // Assumes that the only intersection type is readonly
                List<Type> memberTypes = ((IntersectionType) paramType).getConstituentTypes();
                int size = memberTypes.size();
                if (size > 2) {
                    throw HttpUtil.createHttpError(
                            "invalid header param type '" + paramType.getName() +
                                    "': only readonly intersection is allowed");
                }
                this.readonly = true;
                for (Type type : memberTypes) {
                    if (type.getTag() == TypeTags.READONLY_TAG) {
                        continue;
                    }
                    if (type.getTag() == TypeTags.UNION_TAG) {
                        getEffectiveType(type);
                        return type;
                    }
                    return type;
                }
            }
            return paramType;
        }

        // Note the validation is only done for the non-object header params. i.e for the string, string[] types
        private void validateBasicType(Type type) {
            if (isValidBasicType(type.getTag()) || (type.getTag() == TypeTags.ARRAY_TAG && isValidBasicType(
                    ((ArrayType) type).getElementType().getTag()))) {
                // Assign element type as the type of header param
                this.type = type;
            }
        }

        boolean isValidBasicType(int typeTag) {
            return typeTag == TypeTags.STRING_TAG || typeTag == TypeTags.INT_TAG || typeTag == TypeTags.BOOLEAN_TAG ||
                    typeTag == TypeTags.DECIMAL_TAG || typeTag == TypeTags.FLOAT_TAG;
        }

        public Type getType() {
            return type;
        }

        public boolean isReadonly() {
            return readonly;
        }

        public boolean isNilable() {
            return nilable;
        }
    }
}
